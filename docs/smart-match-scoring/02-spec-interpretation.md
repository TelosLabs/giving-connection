# Smart Match — Reading the Scoring Spec

How to interpret [source/](./source/) — the client's scoring CSVs — as an
implementable model. Source of truth for *intent* is the CSV; source of truth
for *semantics* is this file.

---

## The CSV is three systems, not one

The sheet interleaves them column-by-column. They must be built as separate
layers or they will contaminate each other.

### 1. Hard filters (`Filter` column)

Eligibility gates. An org that fails one must not appear at any score. The CSV
is emphatic about this — `Recommendation Note` repeats *"Treat the filter
separately from ranking score"* on every row that has one.

Filters implementable with **existing** columns:

| Trigger | Predicate | Column |
|---|---|---|
| Path = Find Help | offers services | `locations.offer_services = true` |
| Path = Volunteer | has volunteer opportunities | `organizations.volunteer_availability = true` |
| Donor + `donation_style = general_donation` | has a donation link | `organizations.donation_link` present |
| City selected | in that city's state **+ nationwide orgs** | `locations.state_code` OR `scope_of_work = 'National'` |
| `location_scope = national` | national scope | `organizations.scope_of_work = 'National'` |
| Travel bucket | within radius | `ST_DWithin(locations.lonlat, …)` |

Filters blocked on new fields: remote-services-only, volunteer remote/hybrid
format. See [03-findings-and-gaps.md](./03-findings-and-gaps.md).

### 2. The preset scoring table (`Row 6` / `Row 34` / `Row 49` sheets)

Fully enumerated `answer → field → preset → weight` triples. Fields are
`Populations Served` (→ `beneficiary_subcategories.name`), `Cause` (→
`causes.name`), `Service` (→ `services.name` via `location_services`), `NTEE`
(→ `organizations.irs_ntee_code`), and one `Language` row with no backing
column yet.

Weight conventions the client used consistently:

- **5** — exact Populations Served match (the strongest signal)
- **4** — exact Cause match
- **3** — related Service match, or a weaker/secondary population
- **2** — NTEE code match (coarsest signal)

### 3. Question multipliers (`Question Priority/Weighting` column)

`High (1.5)` · `Medium (1)` · `Low (.5)`. Multiplies every weight earned by
that question's answers.

**Note the trailing space** in the raw CSV: `"High (1.5) "`. Strip before
parsing.

---

## Scoring semantics (decisions, not CSV text)

The CSV specifies weights but not how they compose. These are our rulings —
change them deliberately, not incidentally.

### Contribution

```
contribution = weight × question_multiplier
```

### Per-answer aggregation: MAX, not SUM

An answer lists several presets for the same field. `Children & Youth` maps to
three Populations Served presets at weight 5 each. An org tagged with all
three must **not** score 15 — that rewards tag-spamming.

> **Rule: within one (answer, field) pair, take the single highest matching
> weight.** Sum across different fields, and across different answers.

So `Children & Youth` on a fully-tagged org yields
`5 (population) + 4 (cause) + 3 (service) + 2 (ntee) = 14`, times the 1.5
multiplier = 21 — not 5+5+5+4+4+3+3+2+2.

### Normalization: divide by max achievable

Raw totals are not comparable across submissions. A user selecting five
self-descriptions can earn far more than one selecting a single option, and a
multi-select-heavy path outweighs a sparse one. Left raw, the blend weight
against embedding similarity would drift per user.

> **Rule: `rule_score = earned / max_achievable`, where `max_achievable` is the
> sum of the best possible contribution for that user's actual answer set** —
> i.e. score the user against a hypothetical org that matches everything.
> Yields a stable 0..1 that composes cleanly with cosine similarity.

Compute `max_achievable` from the same table walk, taking each (answer, field)
pair's maximum weight regardless of org content. Guard against zero.

### NTEE prefix matching

Four sheet entries are letter groups, not full codes:

```
O: Youth Development
E: Health Care
G: Voluntary Health Associations & Medical Disciplines
F: Mental Health & Crisis Intervention
```

`organizations.irs_ntee_code` stores full strings like
`"P30: Children & Youth Services"`, validated against
`Organizations::Constants::NTEE_CODE`. A single-letter entry means **match any
code beginning with that letter**. Everything else is exact string equality.

The YAML must distinguish the two — a `match: prefix` flag on those entries, or
detect a single-letter-before-colon pattern. Prefer explicit.

### Escape-hatch answers score nothing

`none`, `no_preference`, `prefer_not_to_say`, `just_exploring`, `not_sure`
carry no signal. They must contribute 0 **and** add 0 to `max_achievable` —
otherwise selecting "no preference" silently depresses a user's normalized
score.

### "Information only" rows

`Recommendation Note = "Do not use for preset scoring"` — these feed the
embedding text (the AI/context layer), not the rule scorer:
`support_for`, `situation`, `giving_inspiration`, `donor_involvement`, and
Personal Details on the Donor/Volunteer paths.

Personal Details on the **Find Help** path *is* scored (age → age-related
populations, gender → gender-related, race → race/ethnicity populations) at
weight +2 × 0.5 multiplier. That mapping is **not** enumerated in any sheet and
must be authored — see the open questions doc.

### Row 49's `Language: Spanish` (weight 5)

The only row referencing a `Language` field. Nothing in the schema backs it.
Blocked on the languages field; the YAML should carry the rule with a
`requires_field:` marker so it activates automatically once the column lands.

### Rows with no preset match

Row 49's `Behind the scenes` and `Accessible or virtual`, and Row 34's
`Spanish-speaking communities` Populations Served row, are explicitly marked
"No reliable preset match". Encode as scoring-nothing so nobody later
"fixes" them with a guess.

---

## Graceful degradation for unbuilt fields

Roughly 40% of the sheet's rows depend on nonprofit fields that don't exist. A
rule referencing a missing field must:

1. contribute 0, **and**
2. be excluded from `max_achievable`

so users who select those preferences aren't penalized for the platform's
missing data. The `requires_field:` marker in the YAML drives both.
