# Smart Match Scoring Refinement

Working knowledge for replacing the Smart Match engine's coarse attribute bonus
with the client's explicit answer-by-answer scoring model.

**Started:** 2026-08-04 · **Branch:** `refine-smart-match`

**Status:** Phases 0–4 built. Phase 5 (new nonprofit fields) is next and needs
client scoping. Phase 6 not started.

| Phase | State | Landed as |
|---|---|---|
| 0 Baseline | ✅ | `spec/services/smart_match/scoring_baseline_spec.rb`, `spec/support/smart_match_scoring_fixtures.rb` |
| 1 Widen `UserIntent` | ✅ | `UserIntent::QUIZ_ANSWERS` + `#answers_by_key`; guards in `quiz_schema_consistency_spec.rb` |
| 2 Rule scorer | ✅ | `config/smart_match_scoring.yml`, `SmartMatch::RuleScorer`, `scoring_rules_consistency_spec.rb`, `rule_scorer_spec.rb` |
| 3 Eligibility filters | ✅ | `SmartMatch::Eligibility`, `SimilarityQuery::Result`, `quiz_submissions.search_relaxations`, "we broadened your search" notice |
| 4 Display calibration | ⚠️ provisional | `matching_rules.yml#display_calibration` — derived arithmetically, needs refitting on real data |
| 5 New nonprofit fields | ⬜ | — |
| 6 City column | ⬜ | — |

**Open and still needing a product decision:** the `statewide` travel option
reads "Remote services only" but applies a 100-mile radius, and no field
exists to fix it (Q6).

---

## Read this first if you are picking up the work

1. [01-current-state.md](./01-current-state.md) — how the engine works today,
   file map, and the authoritative list of quiz answer tokens
2. [02-spec-interpretation.md](./02-spec-interpretation.md) — how to read the
   client's CSV, and the scoring semantics we decided (max-not-sum,
   normalization, NTEE prefixes)
3. [03-findings-and-gaps.md](./03-findings-and-gaps.md) — what validating the
   CSV against the codebase turned up, including two live bugs
4. [04-implementation-plan.md](./04-implementation-plan.md) — the phased plan
5. [05-open-questions.md](./05-open-questions.md) — decisions needed from the
   client; **also the decision log**, record answers there

[source/](./source/) holds the client's four CSVs. They arrived as chat
attachments and existed nowhere else — treat these copies as the source of
truth. Mojibake in the originals (`â` where `–` and `—` belonged) was
corrected; content is otherwise verbatim.

Related: [docs/smart-match-engine.md](../smart-match-engine.md) — the original
build plan for the engine, partly superseded by this work.

---

## The problem in one paragraph

The engine ranks with `0.70 × embedding + 0.20 × attribute_bonus + 0.10 ×
distance`, where the attribute bonus is four coarse booleans — and two of the
four are dead code that never fires (see
[Finding 6](./03-findings-and-gaps.md#finding-6--two-of-todays-four-attribute-signals-are-dead-code-)).
Meanwhile the quiz collects 20 answers and `UserIntent` carries only 7. The
client has now specified, exhaustively, what every answer should be worth and
which nonprofit field it should match against. The work is to make the engine
actually use that.

## Key facts worth not rediscovering

- **The client's preset names are clean.** All ~100 checked against
  `Organizations::Constants` — zero typos. Only the four NTEE letter-group
  entries need special handling.
- **`UserIntent` drops 13 of 20 answers.** All three lookup sheets score
  answers from the dropped set. This is the first blocker.
- **There is no `city` column** on `locations`. Multiple CSV rows filter on
  city. Currently approximated via centroids + PostGIS.
- **Local searches exclude nationwide orgs**, contradicting the CSV on every
  location row.
- **The travel step is mislabeled in production** — "Remote services only"
  applies a 100-mile radius.
- **~40% of the CSV depends on 11 nonprofit fields that don't exist.** The plan
  degrades gracefully without them.

## Scope boundary

In scope: the ranking and filtering pipeline (`UserIntent`, `SimilarityQuery`,
`Scorer`, scoring config, and their specs).

Out of scope unless explicitly asked: quiz copy and step structure, the
embedding service, the org admin UI (except where Phase 5 requires it), and the
main site search.
