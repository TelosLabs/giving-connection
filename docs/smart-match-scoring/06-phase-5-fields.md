# Phase 5 — New Nonprofit Fields

**Decision (2026-08-05): no backfill campaign.** Fields ship empty and fill in
over time as organizations edit their own profiles. Partial coverage is
accepted by design.

This document records the 14 fields, why partial data is safe for scoring but
dangerous for filtering, and what still needs deciding.

---

## There is no data to backfill from

Worth stating plainly, because it shaped the decision: **none of these 14
fields exist anywhere today.** Not as a column, not in the spreadsheet
importer's recognised headers, not derivable from another field. Every value
has to be typed in by a human who knows the organization.

Production reality (973 organizations, verified 2026-08-05):

| | count |
|---|---|
| organizations | 973 (943 active) |
| with at least one org admin who could self-serve | 643 (66%) |
| **with no admin at all** — staff-entry only | **330 (34%)** |
| locations | 1027 |
| organizations with more than one location | 30 |

The 66% is *who could be asked*, not data that exists. A full backfill would
mean ~13,600 human-entered data points.

**Smart Match is not live in production** — `QuizSubmission` doesn't exist
there, because production deploys from `main`. So there is no live traffic
degrading while coverage is thin.

---

## Partial data: safe for scoring, dangerous for filtering

The reasoning behind "not every org has to participate in every filter" holds
for one of these and breaks for the other.

### Scoring — partial data works correctly ✅

`RuleScorer` already excludes a rule whose field is unset from **both** the
earned score and the achievable maximum. So:

- an org with the field set and matching → gets the boost
- an org with the field unset → **is not penalised**, the rule simply doesn't
  apply to it
- the user's normalized score is unaffected by how many orgs happen to have
  answered

Twelve of the fourteen fields are scoring-only. For those, ship the column,
let data trickle in, and ranking gets sharper over time. No campaign needed.

One caveat worth naming: this creates **participation bias**. An org that
fills in its profile can outrank an equally-good org that hasn't, on data
completeness rather than fit. That is arguably a feature — it rewards
maintaining your listing — but it is a real effect, not a neutral one.

### Hard filtering — partial data silently hides organizations ❌

`remote_services` is the only field the client's spec uses as a **filter**
(the "Remote services only" travel option).

With an unset-means-excluded filter and thin coverage, a remote-only search
returns *only the handful of orgs that happened to fill the field in*. If 8
orgs have set it and 200 genuinely offer remote services, the other 192 are
invisible — and nothing signals that to the user. That isn't "ranking among
those who participate"; it's a wrong answer presented as a complete one.

**Resolution: make it a relaxable filter, not an absolute one.** Phase 3
already built exactly this mechanism. `remote_services` joins Tier 2:

- applied first, so genuinely-remote orgs rank alone when there are enough
- dropped when the strict pass returns fewer than `min_results`, with the
  existing "We broadened your search" notice naming it

That gives correct behaviour at every level of coverage, from zero to
complete, with no backfill and no silent hiding.

---

## The 14 fields

Field names below are already present in
[config/smart_match_scoring.yml](../../config/smart_match_scoring.yml) as
`requires_field: true` placeholders. The scoring rules are written and
dormant; adding the column and removing that flag activates each one.

| # | Field | Type | Level | Quiz answer | Weight × multiplier | Role |
|---|---|---|---|---|---|---|
| 1 | `remote_services` | bool | location | travel `statewide` | — | **relaxable filter** |
| 2 | `wheelchair_accessible` | bool | location | prefs | 4 × 1.0 = 4.0 | score |
| 3 | `volunteer_format` | enum | org | volunteer_format | 5 × 1.5 = **7.5** | score |
| 4 | `languages` | array | org | prefs / volunteer_type | 2 × 0.5 / **5 × 1.0** | score |
| 5 | `lgbtqia_affirming` | bool | org | prefs | 4 × 0.5 = 2.0 | score |
| 6 | `accepts_in_kind` | bool | org | donation_style | 3 × 1.0 = 3.0 | score |
| 7 | `volunteer_frequency` | enum | org | volunteer_time | 3 × 1.0 = 3.0 | score |
| 8 | `fundraising_events` | bool | org | volunteer_involvement | 3 × 1.0 = 3.0 | score |
| 9 | `partnership_opportunities` | bool | org | volunteer_involvement | 3 × 1.0 = 3.0 | score |
| 10 | `free_or_sliding_scale` | bool | org | prefs | 2 × 0.5 = 1.0 | score |
| 11 | `no_id_required` | bool | org | prefs | 2 × 0.5 = 1.0 | score |
| 12 | `leadership_attributes` | array | org | prefs | 2 × 0.5 = 1.0 | score |
| 13 | `specific_project_giving` | bool | org | donation_style | 2 × 0.5 = 1.0 | score |
| 14 | `recurring_giving` | bool | org | donation_style | 2 × 0.5 = 1.0 | score |

The client's CSV lists 11 rows, but its volunteer row bundles five separate
fields (#3, #7, #8, #9 plus volunteer opportunity attributes) — hence 14.

### Nullable, always

Every column must be **nullable with no default**. `volunteer_availability`
is the cautionary example: `default: false, null: false` means "does not offer
volunteering" and "nobody has told us" are the same value, and the two cannot
be told apart afterwards. With `NULL`, `RuleScorer` skips the rule; with
`false` it would score a definite no.

This is what makes the no-backfill decision safe. It is not optional.

### Location-level vs organization-level

Only `remote_services` and `wheelchair_accessible` sit on `locations` — a
branch can be step-free while the head office isn't, and an org can run
in-person services at one site and telehealth from another. Only 30 orgs have
more than one location, so this affects few records, but it cannot be changed
later without a second migration and a data move.

---

## Cost per field

| Step | Effort | Notes |
|---|---|---|
| Migration | ~10 min | one nullable column |
| Admin form | ~5 min | Administrate — one line each in `ATTRIBUTE_TYPES` and `FORM_ATTRIBUTES` in [organization_dashboard.rb](../../app/dashboards/organization_dashboard.rb) |
| Self-service form | ~30 min | hand-written Slim in [organizations/edit.html.slim](../../app/views/organizations/edit.html.slim) + one line in `organization_params` |
| Spreadsheet importer | ~10 min | one line in [spreadsheet_parser.rb](../../app/services/spreadsheet_import/spreadsheet_parser.rb), keyed on a new CSV header |
| Activate scoring | ~2 min | remove `requires_field: true` from the YAML |

≈1–1.5 hours per field; ~2–3 days for all 14. The engineering was never the
bottleneck — the data entry was, and that is what this decision removes.

**Add all 14 columns in one migration.** A second migration later is more
disruptive than one wide one now, and it means an org that sits down to update
its profile can fill everything in a single pass.

The self-service form work still matters — it is the *only* way data arrives
now that there is no campaign. Prioritise it over the Administrate side.

---

## Still open

1. **Enum values.** `volunteer_format`: in-person / remote / hybrid.
   `volunteer_frequency`: one-time / event-based / weekly / ongoing. Taken
   from the client's CSV — confirm or amend.
2. **`languages`** — fixed list (filterable, consistent, needs a
   vocabulary decision) or free-text array (captures the long tail, messier to
   match)? The Row 49 rule matches specifically on Spanish.
3. **`leadership_attributes`** — the CSV says "Women- or BIPOC-led". Fixed
   set of attributes, or free text?
4. **Volunteer opportunity attributes** (part of CSV row 11, weight 3) — the
   sheet never enumerates them. Needs a vocabulary before it can be built.
5. **The 330 admin-less organizations** — they will never self-serve. Accepted
   as permanently unset, or does staff fill the highest-weight fields for
   them?
6. **Q6 still stands.** Until `remote_services` ships, the `statewide` travel
   option reads "Remote services only" and applies a 100-mile radius. Shipping
   field #1 is what closes it.
