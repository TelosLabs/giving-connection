# Unused Organization Data

The inverse of [06-phase-5-fields.md](./06-phase-5-fields.md). That document
covers quiz answers with no nonprofit field behind them. This one covers the
opposite gap: **organization data the platform already holds that Smart Match
never reads.**

Audited 2026-08-05 against production (973 organizations, 1,027 locations).
Counts are real, not estimates.

**The question that matters for each item is: can an existing quiz question
already reach this data, or would the flow need a new question?** Everything
reachable by an existing question has been implemented; the rest is listed
under "Needs a new question" at the bottom.

| Data | Reachable today? | Status |
|---|---|---|
| Tags | Yes — free text + causes, semantically via the embedding | ✅ done |
| `general_population_serving` | Yes — the existing population questions | ✅ done |
| Nearest-location distance | Yes — existing city/travel questions | ✅ done |
| PO box locations | Yes — same | ✅ done |
| Office hours | **No** — only hook is `situation`, which the CSV marks do-not-score | ⛔ needs a decision |
| Service-level presets | **No** — needed a new question | ✅ built 2026-08-10 |
| `verified` | No, and a question would be wrong | ⛔ product call |

---

## What Smart Match actually reads today

**Embedding text** (`Organization#smart_match_text`): name,
`mission_statement_en`, `vision_statement_en`, `tagline_en`, cause names,
beneficiary subcategory names, main location address.

**Filtering and scoring**: `active`, `scope_of_work`, `irs_ntee_code`,
`donation_link`, `volunteer_availability`, `volunteer_link`, `languages`, the
8 new capability booleans, causes, beneficiary subcategories, location
services, `locations.main`, `offer_services`, `state_code`, `lonlat`, and the
2 new location booleans.

Everything below is held by the platform and read by none of it.

---

## Ranked by value

### 1. Tags — 2,243 rows across 677 organizations (70%) 🔴

The largest untapped source by far. Tags are free-text descriptors already
powering the main site search (`Locations::Searchable` weights them into its
`pg_search` index) — but Smart Match's embedding text ignores them entirely.

Sample values: *Food banks, Human services, Family services, Arts education,
Vocal music, Public affairs, Performing arts education, Musical ensembles*.

These read like exactly the vocabulary a user types into free text. Adding them
to `smart_match_text` is a one-line change with 70% coverage and no new data
entry.

**Caveat:** changing `smart_match_text` invalidates every stored organization
embedding — all 973 need re-embedding. See the backfill notes in
[deployment](../deployment.md); the per-org `EmbedOrganizationJob.perform_now`
route is the one that works.

### 2. Office hours — 1,014 of 1,027 locations (99%) 🔴

Near-total coverage, completely unused, **and the quiz already asks the
question that needs it.** Find Help step 5 captures
`situation: urgent | long_term | exploring`.

Someone in an urgent situation at 9pm is currently just as likely to be matched
to an organization that closed at 5pm as one that is open. Beyond raw hours:

| `non_standard_office_hours` | locations |
|---|---|
| `no_set_business_hours` | 368 (36%) |
| `always_open` | 67 |
| `appointment_only` | 40 |

"Appointment only" is a meaningful negative signal for an urgent need, and
"always open" a strong positive one. `situation` currently sits in
`ignored_answers` as information-only — this is the field that could make it
matter.

### 3. `general_population_serving` — 54 organizations, and they are being penalised 🔴

**All 54** organizations flagged as serving the general population have **zero**
beneficiary subcategories. That is coherent data entry — the flag exists so an
org doesn't have to enumerate populations — but the scorer only knows how to
match populations.

So every `self_description`, `donor_communities`, and `volunteer_type` rule
scores these organizations **0**, no matter how well they fit. An org that
genuinely serves everyone, including the user, is ranked below one that ticked
a matching population box.

The fix is small: treat `general_population_serving` as satisfying a population
rule at a reduced weight. It needs a product decision on what that weight is,
since "serves everyone" is a weaker signal than "specialises in your
population" but is clearly not zero.

Related: **169 organizations (17%) have zero beneficiaries** — the 54 above
plus 115 with simply-missing data. All are structurally unable to score on any
population rule. This is the participation-bias effect from
[06](./06-phase-5-fields.md#scoring--partial-data-works-correctly-) showing up
in data that already exists.

### 4. Non-main locations ignored — 54 locations across 30 organizations 🟠

`SimilarityQuery#base_scope` filters `locations: {main: true}`, and
`distance_miles` measures from `main_location`. An organization with a branch
2 miles from the user but a head office 40 miles away is scored as 40 miles —
and can be excluded outright by the radius filter.

Note this is inconsistent with the eligibility filters, which were deliberately
written as "any location offers services" and "any location is wheelchair
accessible". Distance should follow the same rule: nearest location, not the
main one.

Affects the same 30 multi-location organizations flagged in
[06](./06-phase-5-fields.md#location-level-vs-organization-level).

### 5. PO Box main locations — 141 (14%) 🟠

141 main locations are PO boxes, geocoded to a post office. Their coordinates
are roughly correct for the town but meaningless for "walking distance only
(under 5 miles)" filtering — the user is being measured against a mailbox.

`Location` already has a `besides_po_boxes` scope for exactly this; Smart Match
doesn't use it. Excluding them outright would hide 14% of organizations, so the
right treatment is probably to report `nil` distance (neutral, the same
treatment nationwide orgs now get) rather than a false precise one.

### 6. `verified` — 112 organizations (12%) 🟡

A trust signal with no effect on ranking. Whether a verified organization
should outrank an unverified equally-good match is a product call, not an
engineering one. Cheap to add as a small scoring term if wanted.

### 7. Spanish content — 6 organizations 🟡

`mission_statement_es` (6), `tagline_es` (3). Too sparse to be worth wiring in
on its own, but it is a real signal that an organization serves Spanish
speakers and could seed the new `languages` field for those few.

---

## Checked and genuinely not relevant

`second_name`, `website`, `email`, `phone_number`, social media links, `suite`,
`youtube_video_link`, images, `time_zone`, `slug`, `ein_number`, `creator`.
Contact and presentation data, no matching signal.

`public_address = false` (14 locations) affects whether an address can be
displayed, not whether the organization matches.

---

## Implemented (2026-08-05)

All reachable by questions the quiz already asks — no flow changes.

- **Tags in `smart_match_text`.** Reached by the free-text box and cause
  selections through embedding similarity, so no new question is needed.
  ⚠️ **Requires re-embedding all 973 organizations before it takes effect.**
- **`general_population_serving` partial credit.** Scored via the existing
  population questions (`self_description`, `donor_communities`,
  `volunteer_type`) at `scoring.general_population_credit` (0.5) of a rule's
  weight, flagged in the match trace as `via: general_population_serving`. An
  exact match always beats it. Set the config value to 0 to disable.
- **Nearest-location distance.** `SimilarityQuery` now joins all locations
  rather than only `main: true`, so an organization is findable at any of its
  sites and measured from the closest one. This was two bugs: a nearby branch
  was excluded by the radius filter *before* distance was ever computed.
- **PO box locations excluded from distance.** They geocode to a post office.
  An organization with only a PO box reports `nil` distance — the neutral
  treatment nationwide organizations already get — rather than false precision.
- **A "how we matched you" panel on the results page.** Every answer the user
  gave, with whether the shown matches meet it: met / partial / unmet /
  not-stated. `RuleScorer` records a per-answer status alongside the score and
  `SmartMatch::CriteriaSummary` aggregates it across the displayed results.
  The four-way split matters — "this organization is not wheelchair
  accessible" and "this organization has not told us" are different answers,
  and only one of them means the user should look elsewhere.

## Needs a new question (or a spec change)

### Office hours — 99% coverage, no usable hook ⛔

The only existing question that could drive it is `situation`
(urgent / long-term / exploring), and **the client's CSV explicitly marks that
"Information only … do not use for preset scoring"**. Using office hours
therefore needs one of:

1. **Amend the CSV** to let `situation` score — then `urgent` could boost
   `always_open` and penalise `appointment_only`. Cheap, no flow change.
2. **A new question**, e.g. "When do you need help?" or "What times work for
   you?" — much stronger, because `situation` says nothing about *when* the
   user is available.

Note that scoring "open right now" would make results time-dependent and
non-reproducible (the same quiz at 2pm and 10pm would rank differently, and
matches are persisted). Prefer time-independent signals — `always_open`,
`appointment_only` — over a live open/closed check.

### Service-level presets — SHIPPED AS A FILTER, NOT A QUESTION 2026-08-14 ✅

`Organizations::Constants::CAUSES_AND_SERVICES` defines roughly 400 services
under 36 causes, and organizations are tagged with them via `location_services`.
The quiz only ever asks for **causes** — the top level. A user picking
"Housing & Homelessness" cannot say whether they need *Homeless Shelters*,
*Housing Search Assistance*, or *Home Improvement & Repairs*.

A services **quiz step** was built for this on 2026-08-10 (scored at 5 × 1.5,
one proportional slot for the whole question) and **removed on 2026-08-14**. It
worked as a refinement for the minority who know the vocabulary and added
friction for everyone else: asked as a standalone question, before any results
existed, it made people stop and wonder what a "service" is and whether they
were supposed to know. A yes/no gate in front of it would have provoked exactly
the same question, so the step is gone rather than hidden behind one.

Services now live **after** the results, as an optional filter on the results
page — `SmartMatch::ServiceFilter` plus
`app/views/smart_match/results/_service_filter.html.erb`, collapsed under
"Looking for a specific service?". Three properties matter:

* **It never touches scoring.** `config/smart_match_scoring.yml` has no
  `services` question, `UserIntent::QUIZ_ANSWERS` has no `services` key, and the
  filter only narrows an already-ranked, already-persisted match list. The
  cause questions still credit an organization's services through their
  `cause_service` rules, which predate all of this.
* **Its options are the services the matched organizations actually offer**,
  each with a count, rather than the full 274-name vocabulary — so the list is
  scannable and no click can empty the page.
* **The need is concrete by then.** Someone looking at six food banks and
  realising they need eviction help has the intent the quiz question was
  fishing for; someone who does not simply never opens the panel.

Removing the step renumbered all three flows back to their pre-2026-08-10
numbering (`STEPS_BY_USER_TYPE`, `LOCATION_DETAIL_STEP`,
`SERVICE_SEEKER_TRAVEL_STEP`, `SERVICE_SEEKER_PREFERENCES_STEP`); the specs
derive step numbers from those constants rather than hard-coding them.

Because services were the only `aggregate: proportional` question, that
machinery went with them: `RuleScorer#score_proportional_question`,
`RuleScorer::PARTIAL`, and the `grouped` / `matched_count` / `selected_count`
fields on criteria. A per-criterion status is now met / unmet / unknown only.

### `verified` — 112 organizations ⛔

No question would be appropriate ("do you want only verified organizations?"
pushes work onto the user). If it should matter, it belongs as a flat ranking
bonus, which is a product decision rather than a flow change.
