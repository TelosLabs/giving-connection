# Smart Match Scoring — Implementation Plan

Phases are ordered so each ships independently and is reversible. Read
[02-spec-interpretation.md](./02-spec-interpretation.md) and
[03-findings-and-gaps.md](./03-findings-and-gaps.md) first.

**Blocked on:** the four decisions in
[05-open-questions.md](./05-open-questions.md). Phase 0 and 1 can start
without them.

---

## Target architecture

```
UserIntent (all 20 answers)
      │
      ├──► Eligibility ─────────► SimilarityQuery (hard filters + kNN)
      │                                   │
      │                                   ▼
      └──► RuleScorer ──────────────► Scorer ──► blended score + itemized breakdown
                 ▲
                 │
      config/smart_match_scoring.yml
```

Three new units, one rewritten:

| Unit | Responsibility |
|---|---|
| `config/smart_match_scoring.yml` | the entire declarative scoring table |
| `SmartMatch::Eligibility` | build the hard-filter predicate from an intent |
| `SmartMatch::RuleScorer` | walk the YAML, return normalized 0..1 + breakdown |
| `SmartMatch::Scorer` (rewrite) | blend embedding + rules + distance |

Keeping filters out of the scorer is not stylistic — the CSV demands it on
nearly every row ("Treat the filter separately from ranking score").

---

## Build notes (2026-08-04)

Things learned while implementing Phases 0–2 that aren't obvious from the
plan:

- **YAML eats `19_24`.** Bare `19_24` parses as the integer `1924` (underscore
  digit separator), so the age-range keys silently stopped matching their
  answer tokens. Quote any answer token that looks numeric. Caught by the
  answer-coverage drift spec, which is the argument for having written it.
- **`impact_location` isn't preset-scored.** Its CSV rules (local match,
  city/ZIP proximity, "no geographic weight" for Anywhere) are filtering and
  distance concerns. It sits in `ignored_answers` pointing at Phase 3.
- **The `causes` question can't be enumerated** — the answer *is* a cause name.
  It uses a `"*"` catch-all answer plus `match: answer` / `match: cause_service`
  rules that resolve against the selected value. `none` overrides the catch-all.
- **The CSV's "+3 Related Services match" tier is not implemented.** "Related"
  is undefined and nothing in the data drives it; the nearest signal (cause
  synonyms) already feeds the embedding layer, so implementing it here would
  double-count. Flagged rather than guessed.
- **Two questions share the `causes` session key** with different weights per
  path, hence the `session_key:` alias on the `causes_donor` entry.
- **Breakdown key types.** `score_breakdown` nests symbol-keyed hashes that
  become strings in jsonb. The baseline spec round-trips through JSON before
  comparing; anything reading the trace back out of the DB gets strings.

## Phase 0 — Baseline

Cheap, and everything downstream depends on it.

- Pick ~10 representative submissions spanning all three paths (single-select
  and multi-select heavy, local and nationwide, with and without free text).
- Capture current ranked output + score breakdowns to a fixture.
- A rake task or spec that replays them and diffs is ideal; a committed JSON
  snapshot under `spec/fixtures/smart_match/` is the minimum.

Without this there is no way to tell an improvement from a regression —
especially given Finding 6 (two of four current signals are dead), which means
current output is worse than it looks.

**Exit:** baseline committed, reproducible.

---

## Phase 1 — Widen `UserIntent`

Pure widening. No behavior change; existing specs must pass untouched.

- Add the 13 dropped `attr_accessor`s to
  [user_intent.rb](../../app/models/user_intent.rb) (list in
  [01-current-state.md](./01-current-state.md#what-userintent-carries-vs-what-the-quiz-collects)).
- Populate them in `.from_session`, reusing `parse_array` for multi-selects.
- **Drift guard spec:** every value in `QuizNavigator::PARAM_SESSION_MAP` has a
  corresponding `UserIntent` accessor. Same spirit as
  `quiz_schema_consistency_spec.rb`. This is what stops the next new question
  from being silently dropped.
- Decide whether any newly-available answers should join
  `#to_embedding_text`. Probably yes for `situation` and `giving_inspiration`
  (the CSV explicitly routes them to "the AI/context layer"). Changing
  embedding text **invalidates stored quiz embeddings** — org embeddings are
  unaffected, but note it and keep it a separate commit from the accessor
  widening so it can be reverted alone.

**Exit:** all answers reachable from `UserIntent`; green suite.

---

## Phase 2 — The rule scorer

The core of the work.

### 2a. `config/smart_match_scoring.yml`

Transcribe [source/](./source/) into config. Loaded and deep-frozen alongside
the existing YAMLs in [app/services/smart_match.rb](../../app/services/smart_match.rb)
— note the comment there explaining why these constants live in that file and
**not** in an initializer (Zeitwerk reload behavior). Follow it.

Draft shape (refine during implementation; keep it boring and flat):

```yaml
questions:
  self_description:                 # session key
    paths: [service_seeker]
    multiplier: 1.5
    answers:
      children_youth:
        - {field: population, preset: "Children & Youth", weight: 5}
        - {field: population, preset: "Individuals Under 21", weight: 5}
        - {field: population, preset: "Non-Adults", weight: 5}
        - {field: cause, preset: "Children & Family Services", weight: 4}
        - {field: cause, preset: "Youth Development", weight: 4}
        - {field: service, preset: "Children & Family Services", weight: 3}
        - {field: service, preset: "Youth Specific Services", weight: 3}
        - {field: ntee, preset: "P30: Children & Youth Services", weight: 2}
        - {field: ntee, preset: "O", weight: 2, match: prefix}
      none: []                      # explicit: escape hatch scores nothing

  prefs:
    paths: [service_seeker]
    multiplier: 0.5
    answers:
      wheelchair_accessible:
        - {field: wheelchair_accessible, weight: 4, requires_field: true,
           multiplier_override: 1.0}     # CSV marks this row Medium, not Low
      lgbtqia_affirming:
        - {field: population, preset: "LGBTQ+ People", weight: 2}
        - {field: service, preset: "LGBTQ+ Advocacy", weight: 3}
```

Design notes:

- `field:` values map to resolver methods on the candidate, not to raw columns
  — one indirection point when the schema moves.
- `match: prefix` only for the four NTEE letter groups.
- `requires_field: true` marks rules blocked on unbuilt columns — contributes 0
  **and** is excluded from `max_achievable` (Finding 4).
- `multiplier_override` handles the CSV rows where one answer within a question
  carries a different priority than its siblings (the `prefs` question mixes
  Low and Medium; `donation_style` mixes High, Medium, and Low).
- Escape-hatch answers get explicit empty lists, not omission — omission reads
  as "not yet transcribed".

### 2b. `SmartMatch::RuleScorer`

```ruby
SmartMatch::RuleScorer.call(organization:, user_intent:)
# => { score: 0.0..1.0, earned: Float, max: Float, matched: [ ... ] }
```

- Walk each question applicable to the intent's path; for each selected answer,
  for each field group, take **max** matching weight (never sum within a group
  — see spec interpretation); multiply by the question multiplier.
- Compute `max_achievable` in the same walk. Guard divide-by-zero.
- `matched:` is an itemized trace —
  `"self_description:senior → population:Seniors = 5 × 1.5 = 7.5"`. This is
  what makes the system tunable with the client and debuggable in production.
  It goes into `OrganizationMatch#score_breakdown` (already `jsonb`, no
  migration needed) — but check the column's practical size once real
  breakdowns land; truncate the trace if it bloats.
- Preload everything the resolvers touch. `SimilarityQuery#base_scope` already
  `includes(organization: [:causes, :beneficiary_subcategories, {locations: :services}])`;
  `irs_ntee_code` and `donation_link` are plain columns. **Do not add a query
  per candidate** — this runs over up to `max_results` (20) orgs per
  submission.

### 2c. Drift-guard spec

Assert every `preset:` in the YAML exists in `Organizations::Constants`
(exact for `population`/`cause`/`service`, prefix-valid for `ntee`). Without
this, a renamed cause scores zero forever and silently. Model it on
`spec/services/smart_match/quiz_schema_consistency_spec.rb`.

Also assert: every quiz answer token appears in the YAML (or an explicit
`ignored:` list), so a new quiz option can't be added without a scoring
decision.

### 2d. Blend into `Scorer`

Add `rule_score` as a fourth weighted term in `matching_rules.yml#scoring.weights`,
keeping the four weights summing to 1.0. Start conservative, then tune against
the Phase 0 baseline. Recommendation pending decision Q1; suggested start:

```yaml
weights:
  embedding_similarity: 0.45
  rule_score:           0.45
  attribute_bonus:      0.00   # retire — superseded by rule_score (Finding 6)
  distance:             0.10
```

Retiring `attribute_bonus` rather than keeping both avoids double-counting
cause matches. Keep the key at 0.0 for one release so it can be dialled back
up if the rule scorer misbehaves in production.

**Exit:** rule scores computed and visible in breakdowns; ordering change
reviewed against baseline; weights tunable without a deploy.

---

## Phase 3 — Hard filters

- New `SmartMatch::Eligibility` producing a predicate/scope from the intent.
- Wire into `SimilarityQuery` — path filters (`offer_services`,
  `volunteer_availability`, `donation_link`), nationwide inclusion for local
  searches (Finding 2), corrected travel radii (Finding 3).
- Decide and implement the **zero-results fallback** (decision Q2) — if filters
  are strictly conjunctive, a specific query can legitimately return nothing.
  Whatever the policy, the UI must state when results were broadened.
- Extend `spec/queries/smart_match/similarity_query_spec.rb`: each filter in
  isolation, filters in combination, and the zero-result path.

**Exit:** ineligible orgs cannot appear at any score; broadening is explicit.

---

## Phase 4 — Recalibrate display

Sample the raw score distribution post-Phase-2/3 and refit
`display_calibration` (`input_floor`, `input_ceiling`, `min_percentage`,
`max_percentage`). Presentation only — strictly monotonic, ordering unaffected.
Sanity-check the extremes: a perfect match should not read 100%, a weak one
should not read 90%.

**Exit:** displayed percentages track perceived quality again.

---

## Phase 5 — New nonprofit fields

The largest phase and mostly **not** a coding problem. Scope with the client
before starting. Per field: migration → org admin form → spreadsheet importer →
serializer/display → backfill campaign → flip `requires_field` on in the YAML.

Sequence by value-per-effort. Suggested first three: wheelchair accessible
(highest CSV weight at +4), remote services (unblocks the Finding 3 bug), free
or sliding-scale (highest user demand for the Find Help path).

Get the org-level vs location-level distinction right the first time —
wheelchair accessibility and remote services are location-level; the rest are
org-level.

Model unknown ≠ no (nullable, or a completeness guard), so an unfilled field
skips the rule rather than scoring it false. Otherwise launch day drops every
org out of every preference-filtered result.

---

## Phase 6 — City column (conditional on decision Q3)

`locations.city`, backfilled from the geocoder, indexed. Enables exact city
filtering per the CSV and is reusable by the main site search. Independent of
Phases 2–4, which run on centroid+radius.

---

## Testing strategy

| Phase | Coverage |
|---|---|
| 0 | replayable baseline fixture |
| 1 | `PARAM_SESSION_MAP` ↔ `UserIntent` drift guard |
| 2 | RuleScorer units (max-not-sum, normalization, prefix NTEE, escape hatches, missing-field skip); YAML ↔ constants drift guard; answer-coverage guard |
| 3 | each filter isolated + combined; zero-result fallback |
| 4 | calibration monotonicity + boundary values |
| 5 | per field: migration, form, import, scoring activation |

Existing specs in `spec/services/smart_match/` and
`spec/queries/smart_match/` must stay green throughout Phases 0–1 and be
updated deliberately (not incidentally) in Phases 2–4.

---

## Rollback

Every phase is config-reversible except the migrations in Phase 5:

- Phase 2 → set `rule_score: 0.0`, restore `attribute_bonus: 0.20`
- Phase 3 → `Eligibility` behind a config flag returning an identity scope
- Phase 4 → revert four numbers in `matching_rules.yml`
