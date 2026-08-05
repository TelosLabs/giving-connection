# Smart Match Scoring — Open Questions

Decisions needed before Phase 2. Phases 0 and 1 can proceed without them.

**Status as of 2026-08-04:** Q1 and Q5 provisionally resolved in code so
Phase 2 could ship; both are cheap to change and still want client sign-off.
Q2, Q3, Q4, Q6 remain open. Record answers inline as they land — this file is
the decision log.

---

## Q1 — How much should deterministic rules outweigh embedding similarity? 🔴

**Blocks:** Phase 2d

The engine today is embedding-first (0.70). The CSV reads like the client wants
deterministic scoring to lead. These pull in opposite directions and the split
determines whether the sheet actually changes results.

| Option | Effect |
|---|---|
| Rules dominant (0.25 / 0.65) | sheet is the ranking; embedding breaks ties. Predictable, explainable, brittle for orgs with sparse tagging |
| Balanced (0.45 / 0.45) | **recommended start.** Semantic recall from embedding, hard preferences from rules |
| Embedding-led (0.60 / 0.30) | closest to today; the sheet nudges rather than decides |

**Recommendation:** start balanced, tune against the Phase 0 baseline with the
client looking at real result sets. It's a YAML value — cheap to move once the
breakdown trace exists to justify the move.

**Watch:** orgs with thin cause/beneficiary tagging get punished as rules gain
weight. Check the tagging-completeness distribution before going rules-dominant.

**Answer:** _provisionally balanced_ — shipped as
`embedding_similarity 0.45 / rule_score 0.45 / attribute_bonus 0.00 /
distance 0.10` in `config/matching_rules.yml`. `attribute_bonus` is retired
rather than kept alongside `rule_score` (it scored the same cause signal, so
running both double-counted); it stays wired at 0.0 for one release as a
rollback lever.

Effect on the committed baseline: four of eight scenarios changed order, and in
each the intuitively-correct organization moved to rank 1 — the LGBTQ+ centre
and the racial-equity org went from outside the top four to first. Still wants
client review against real result sets before being called settled.

---

## Q2 — Do hard filters ever relax? 🔴

**Blocks:** Phase 3

Filters are conjunctive. "Nashville + wheelchair accessible + Spanish +
sliding scale" will legitimately return **zero** orgs. The CSV is silent.

| Option | Effect |
|---|---|
| Strict | honest, never wastes a user's time on a bad referral; empty page is a poor experience for someone in need |
| Tiered relaxation | keep path + geography hard; relax preference filters in a defined order, label results "broadened because…" |
| Always show closest | never empty; risks sending someone to a service they can't physically access |

**Recommendation:** tiered. Path eligibility (offers services / has volunteer
opportunities / has donation link) and geography stay hard; Section 4
preferences relax. **Any relaxation must be visible in the UI** — a wheelchair
user must never be shown an inaccessible org without knowing why it's there.

This is a product/UX call, not an engineering one. Needs the client.

**Answer: RESOLVED (2026-08-05) — tiered, with a visible notice.**

Two tiers, implemented in `SmartMatch::Eligibility`:

| Tier | Filters | Behaviour |
|---|---|---|
| required | active org, geography, "any location offers services" (Find Help) | never dropped |
| relaxable | volunteer capability, donation link | dropped as a set when the strict pass returns fewer than `min_results`, and only if dropping them actually finds more |

`SimilarityQuery` returns a `Result` carrying `candidates` plus `relaxed`
(the labels it gave up on). That is persisted to
`quiz_submissions.search_relaxations` and rendered as the "We broadened your
search" notice on the results page, naming the specific filter — a volunteer
needs to know these organizations may not have opportunities.

Not implemented: progressive shedding (drop the lowest-weight filter first).
The two relaxable filters live on mutually exclusive paths, so at most one is
ever active and set-dropping is equivalent. Revisit when Tier 4 preference
filters land in Phase 5.

---

## Q3 — How do we match cities without a `city` column? 🟠

**Blocks:** Phase 3 (exact city filtering) and Phase 6

See [Finding 1](./03-findings-and-gaps.md#finding-1--there-is-no-city-column-).
Centroid+radius (works now, approximate), `ILIKE` on address (fragile), or add
and backfill a real column (exact, migration + backfill).

**Recommendation:** centroid+radius for Phases 2–4; make the column a separate
scoped decision. Ask the client how literal "Address City = Nashville" is —
does a Brentwood org count as Nashville? Their answer decides whether the
approximation is even wrong.

**Answer:** _pending_

---

## Q4 — Are the 11 new nonprofit fields committed work? 🟠

**Blocks:** Phase 5 scoping (not Phases 2–4, which degrade gracefully)

See [Finding 4](./03-findings-and-gaps.md#finding-4--eleven-nonprofit-fields-dont-exist-).
Each is migration + admin form + importer + a data-entry campaign across the
existing org base.

Needed from the client:

1. Committed roadmap or aspirational? The YAML schema accommodates both, but
   priority order changes what we build first.
2. **Who backfills?** A boolean that is false everywhere because nobody filled
   it in is worse than no field — it actively suppresses matches. Org
   self-service, admin bulk entry, or import from an external source?
3. Confirm the org-level vs location-level split (wheelchair accessibility and
   remote services are location-level; the rest org-level). Getting this wrong
   means a second migration.

**Answer:** _pending_

---

## Q5 — Personal Details → Populations Served mapping 🟡

**Blocks:** the Find Help Personal Details rules in Phase 2a

The CSV scores age / gender / race on the Find Help path at +2 × 0.5 but
**never enumerates the mapping** — no Row-6-style sheet exists for it. It has
to be authored. Some are mechanical:

- `under_18` → `Children & Youth`, `Individuals Under 21`, `Non-Adults`
- `over_65` → `Seniors`, `Retired People`
- `female` → `Women & Girls`; `male` → `Men & Boys`
- `black_african_american` → `People of African Descent`; `asian` → `People of Asian Descent`; etc.

Others have no clean preset: `non_binary` (there is `LGBTQ+ People` and
`Intersex People`, neither correct), `hispanic_latino` → `People of Latin
American Descent` (arguably conflating ethnicity with descent),
`middle_eastern_north_african` → `People of Middle Eastern Descent` (drops
North African), the mid-range age buckets (`25_34` … `55_64` all → `Adults`,
which is nearly every org).

**Recommendation:** draft the mapping, then have the client confirm — this is
demographic categorization affecting who sees which services, and a
well-intentioned wrong guess here has real consequences for real people. Leave
unmapped answers explicitly unmapped rather than approximating; the CSV itself
hedges with *"when a corresponding preset exists"*.

Note these are also the lowest-weight rules in the entire sheet (+2 × 0.5 = 1.0
contribution). Low stakes for ranking, higher stakes for getting the
representation right. Defer if it slows Phase 2 — there is no ranking cost to
shipping without them.

**Answer: RESOLVED (2026-08-05) — follow the CSV. All three are scored on the
Find Help path.** The CSV is the source of truth; Donor and Volunteer keep the
sheet's "Information only" treatment, enforced by `paths: [service_seeker]`.

> An earlier decision the same day removed these as "internal statistics only"
> and was reversed. Recorded because the reversal is the reason the mappings
> below were authored rather than deferred.

**The rule for mapping:** the CSV enumerates presets for age but qualifies
gender and race with *"when a corresponding preset exists"*. That qualifier
decides where mapping stops — an answer maps only where a Populations Served
preset means the same thing, and gets an empty list otherwise. At 1.0
contribution (the sheet's lowest), a near-miss is worse than no signal.

| Answer | Maps to | Why |
|---|---|---|
| `under_18` | Children & Youth, Individuals Under 21, Non-Adults | exact |
| `19_24` | Individuals Under 21, Adults | spans both |
| `25_34` … `55_64` | Adults | the CSV's own example; near-zero discriminating power |
| `over_65` | Seniors, Retired People | exact |
| `female` / `male` | Women & Girls / Men & Boys | exact |
| `non_binary` | — | no equivalent. Intersex People is a different thing; LGBTQ+ People is an umbrella, not the "exact gender-related match" asked for |
| `asian`, `black_african_american`, `hispanic_latino`, `native_american`, `native_hawaiian` | matching descent preset + People of all Racial Minority Groups | exact |
| `middle_eastern_north_african` | People of Middle Eastern Descent + minority groups | closest available — the vocabulary has no North African preset |
| `white` | People of European Descent | deliberately **not** paired with the minority-groups preset |
| `other` (gender or race) | — | means "none of the above", which no preset means |
| `prefer_not_to_say` | — | escape hatch |

Pairing each descent preset with "People of all Racial Minority Groups" widens
what can match without inflating anything: only the highest weight in a field
group counts, so an org carrying both scores the same as one carrying either.

Baseline effect: three Find Help scenarios move by <0.01, no ordering change.

---

## Q6 — What happens to the mislabeled `statewide` travel option? 🟡

**Blocks:** Phase 3

See [Finding 3](./03-findings-and-gaps.md#finding-3--the-travel-step-is-already-mislabeled-).
The option reads "Remote services only" and applies a 100-mile radius. It's
wrong today, independent of this project.

Options: hide the option until the remote-services field exists; keep it as
widest-radius with corrected copy; or ship the remote-services field early
(promote from Phase 5) and fix it properly.

**Recommendation:** correct the other three radii immediately in Phase 3 (pure
win, no dependency), and promote the remote-services field to the front of
Phase 5 so this option can mean what it says. Interim copy change if the field
will take a while.

**Answer: RESOLVED (2026-08-05).** The three real radii now match their labels
(`nearby` 5, `moderate` 10, `far` 100), and `remote_services` shipped early
from Phase 5 so the fourth option finally means what it says.

"Remote services only" is now a **relaxable filter** on
`locations.remote_services`, not a radius. Relaxable rather than absolute
because the field ships with no data: as an absolute filter it would show only
the handful of organizations that had answered and silently hide everyone
else. Relaxed, the user gets the widest radius plus a "we broadened your
search — these may not all offer remote services" notice.

The session token is still `statewide`, deliberately. Renaming it would strand
in-flight sessions and every historical `QuizSubmission`; the mapping is
written down once as `SmartMatch::Eligibility::REMOTE_ONLY_TRAVEL_BUCKET`.
