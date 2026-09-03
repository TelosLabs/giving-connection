# Smart Match — Findings & Gaps

Results of validating the client's scoring CSV against the codebase on
2026-08-04. Each finding is stated with the evidence so it can be re-checked
rather than re-discovered.

---

## Finding 0 — The preset vocabulary is clean ✅

All ~100 `Preset Match` strings across the three lookup sheets were checked
against `Organizations::Constants`. **Every** Populations Served, Cause, and
Service name matches a real preset exactly — no typos, no invented values. The
client clearly worked from the live vocabulary.

Only exception: the four NTEE letter-group entries described in
[02-spec-interpretation.md](./02-spec-interpretation.md#ntee-prefix-matching).

Reproduce:

```bash
# extract the Preset Match column, grep each against the constants file
awk -F, 'NR>1 && $3 != "" {print $3}' docs/smart-match-scoring/source/row-*.csv |
  sort -u | while read -r name; do
    grep -qF "\"$name\"" app/models/organizations/constants.rb || echo "MISSING: $name"
  done
```

Keep this as a drift guard — see Phase 2 in the implementation plan.

---

## Finding 1 — There is no `city` column 🔴

Multiple rows demand `Location Address City = Nashville` as a **hard filter**.
The `locations` table has:

```
address (string) · latitude · longitude · lonlat (geography) · state_code (char 2)
```

No city. City is currently approximated via `config/city_centroids.yml` +
`ST_DWithin`. As specified, exact city filtering is not implementable.

Options:

| Approach | Pro | Con |
|---|---|---|
| Centroid + radius (status quo) | works now, no migration | approximate; a suburb 12mi out is "not Nashville" |
| `ILIKE '%Nashville%'` on `address` | no migration | fragile; misses "Nashville-Davidson", hits street names |
| Add `locations.city`, backfill from geocoder | exact, indexable, reusable outside Smart Match | migration + backfill across all locations |

**Recommendation:** ship Phases 2–4 on centroid+radius, and treat the `city`
column as its own scoped piece of work (Phase 6). Do not block scoring on it.

---

## Production data (verified 2026-08-05)

Queried directly against production. **The dev database is a thin, stale seed
and is not representative — do not size decisions from it.**

| | prod (973 orgs) | dev (56) |
|---|---|---|
| active | 943 | 56 |
| `volunteer_availability` true | 597 (61%) | **0** |
| `volunteer_link` present | 544 | — |
| either of the above | **597** | — |
| `donation_link` present | 806 (83%) | 8 |
| scope Regional / National / International | 873 / 73 / 27 | 47 / 6 / 3 |

Two things follow:

- **The volunteer filter is safe.** 61% coverage, not the data-absence trap
  dev suggested.
- **`volunteer_link` is a strict subset of `volunteer_availability`** — the
  OR of the two is exactly 597, identical to the flag alone. It is still
  written as an OR so the filter stays correct if they ever diverge, but it
  buys nothing today.

Read-only production access is available via
`kamal app exec -d production -r web --reuse "bin/rails runner '...'"`.
Target the `web` role: a bare `kamal app exec` fans out to worker and clock
too, and clock OOMs.

## Finding 2 — Local searches exclude nationwide orgs 🔴

Every location row in the CSV says *"Nationwide organizations remain
eligible."* But [similarity_query.rb:65-81](../../app/queries/smart_match/similarity_query.rb#L65-L81)
filters local searches strictly on `locations.state_code`. A `National`-scope
org with no Tennessee location is **invisible** to a Nashville seeker today.

This changes the candidate pool, not the ranking. Fix in `SimilarityQuery`:
the local predicate becomes `state_code = ? OR scope_of_work = 'National'`.

Watch the interaction with radius expansion — national orgs have no meaningful
distance to the user, so they must bypass the `ST_DWithin` narrowing rather
than being filtered out by it. The CSV's corresponding *score* rule is the
`Weight +3: Regional/state service coverage` line, and for the Nationwide
answer, `Weight +2: Organization also has a location near the user`.

---

## Finding 3 — The travel step is already mislabeled 🟠

Live bug, independent of this work.

[en.yml](../../config/locales/en.yml) `smart_match.quiz.steps.travel.options`
already matches the CSV's wording, but `matching_rules.yml#radius_by_travel_bucket`
does not match the wording's meaning:

| Token | Label shown to users | Radius today | CSV says |
|---|---|---|---|
| `nearby` | Walking distance only (under 5 miles) | 5 | 5 ✅ |
| `moderate` | Public transit or rides (5–10 miles) | **15** | 10 ❌ |
| `far` | Car or ride share available (10+ miles) | **30** | 100 ❌ |
| `statewide` | **Remote services only** | **100 mi** | not a radius — a hard filter on remote services ❌ |

`statewide` is the serious one: a user asking for remote-only services gets a
100-mile physical radius instead. The token name is a leftover from an earlier
copy revision.

Fix requires: correcting the radii, and rerouting `statewide` from a radius to
a remote-services filter — which is blocked on the remote-services field
(Finding 4). Interim: treat it as the widest radius and note the limitation,
or hide the option until the field exists. **Needs a product call.**

Also rename the token (`statewide` → `remote_only`) when the field lands, with
a session-value migration or a back-compat alias.

---

## Finding 4 — Eleven nonprofit fields don't exist 🟠

Roughly 40% of the CSV's rows are gated on these. None exist in `schema.rb`.

| # | Field | Type | Used by | CSV weight |
|---|---|---|---|---|
| 1 | Remote services available | bool | Find Help travel (hard filter) | filter |
| 2 | Free or sliding-scale services | bool | `prefs: free_sliding_scale` | +2 × 0.5 |
| 3 | ID / documentation required | bool | `prefs: no_id_required` | +2 × 0.5 |
| 4 | Languages available | array/assoc | `prefs: multilingual`, Row 49 Spanish | +2 × 0.5 / +5 |
| 5 | Wheelchair accessible location | bool | `prefs: wheelchair_accessible` | +4 × 1.0 |
| 6 | LGBTQIA+ affirming services | bool | `prefs: lgbtqia_affirming` | future +4 |
| 7 | Organization leadership attributes | array | `prefs: women_bipoc_led` | +2 × 0.5 |
| 8 | Specific project/campaign giving | bool | `donation_style: specific_project` | +2 × 0.5 |
| 9 | Accepts in-kind donations | bool | `donation_style: goods_items` | +3 × 1.0 |
| 10 | Recurring giving available | bool | `donation_style: recurring_giving` | +2 × 0.5 |
| 11 | Volunteer format / frequency / attributes; fundraising events; business partnerships | enum + bools | all Volunteer Section 2–3 | +3 to +5 |

Note #5 and #1 are **location-level** (a org may have one accessible site and
one not); the rest are org-level. Getting that wrong now means a second
migration later.

Each field is not just a migration — it needs the org admin form, the
spreadsheet importer, and a data-entry campaign across existing orgs. A boolean
that is `false` everywhere because nobody filled it in is worse than no field:
it actively suppresses matches. Any new field should distinguish
*"no"* from *"unknown"* (nullable boolean, or a `data_completeness` guard) so
scoring can skip unknowns instead of penalizing them.

**Fields that already exist and need no work:** `donation_link`,
`volunteer_availability`, `volunteer_link`, `scope_of_work`,
`general_population_serving`, `locations.offer_services`, `irs_ntee_code`,
`locations.state_code`.

---

## Finding 5 — Normalization is unspecified 🟠

Covered in [02-spec-interpretation.md](./02-spec-interpretation.md#normalization-divide-by-max-achievable).
Restated here because it's the single easiest thing to get silently wrong:
without per-submission normalization, users who tick more boxes systematically
outrank users who tick fewer, regardless of actual fit.

---

## Finding 6 — Two of today's four attribute signals are dead code 🟡

`Scorer#beneficiary_match?` and `#service_match?` both test `prefs_selected`
against preset **names**. `prefs` values are UI tokens (`free_sliding_scale`,
`wheelchair_accessible`, …) which never equal a beneficiary or service name.
Both are permanently false in production.

So the current `attribute_bonus` is effectively `(5 × cause) + (2 × scope) / 11`
— and the 0.20 attribute weight is delivering less signal than the config
implies. Relevant when calibrating: the rule scorer will inject genuinely new
signal, and the resulting score distribution will shift more than the weight
change alone suggests.

This is *why* the rewrite is worth doing, and it means the Phase 0 baseline is
essential — current output is not the quality bar we think it is.

---

## Finding 7 — Display calibration will need retuning 🟡

`matching_rules.yml#display_calibration` maps raw `0.38–0.66` onto a displayed
`52–95%`. Those bounds were fitted to an embedding-dominated distribution. Once
rule score carries real weight the raw band moves, and the displayed
percentages become misleading (a great match could read 100%, or a poor one
60%). Recalibrate from the Phase 2 output distribution — it's presentation
only and never affects ordering, per the comment in the config.
