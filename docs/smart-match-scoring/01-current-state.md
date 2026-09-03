# Smart Match — Current Engine State

**Snapshot date:** 2026-08-04 · **Branch:** `refine-smart-match`

Describes the engine *as it exists before* the scoring refinement. If you are
resuming this work later, re-verify against the code — this is a snapshot, not
a live contract.

---

## Pipeline

```
Quiz (11 steps)  →  session[:smart_match_*]  →  UserIntent  →  embedding text
                                                    ↓
                                            EmbeddingClient (BGE, 1024-dim)
                                                    ↓
                                            SimilarityQuery  (HARD FILTERS + pgvector kNN)
                                                    ↓
                                            Scorer           (RANKING)
                                                    ↓
                                            OrganizationMatch rows (score, breakdown, rank)
                                                    ↓
                                            SmartMatchCard::Component (display calibration)
```

Runs off-request in `SmartMatch::ProcessSubmissionJob`; the results page polls
`#status` until matches land.

## File map

| Concern | File |
|---|---|
| Namespace + frozen config loading | [app/services/smart_match.rb](../../app/services/smart_match.rb) |
| Ranking | [app/services/smart_match/scorer.rb](../../app/services/smart_match/scorer.rb) |
| Candidate retrieval + hard filters | [app/queries/smart_match/similarity_query.rb](../../app/queries/smart_match/similarity_query.rb) |
| Answer → intent object | [app/models/user_intent.rb](../../app/models/user_intent.rb) |
| Orchestration | [app/services/smart_match/submission_processor.rb](../../app/services/smart_match/submission_processor.rb) |
| Session writes / step skipping | [app/services/smart_match/quiz_navigator.rb](../../app/services/smart_match/quiz_navigator.rb) |
| Step → partial/section map | [app/services/smart_match/quiz_step_config.rb](../../app/services/smart_match/quiz_step_config.rb) |
| Tunable config | [config/matching_rules.yml](../../config/matching_rules.yml) |
| Preset vocabularies | [app/models/organizations/constants.rb](../../app/models/organizations/constants.rb) |
| Quiz answer values | [app/views/smart_match/quizzes/steps/](../../app/views/smart_match/quizzes/steps/) |
| Answer labels | `config/locales/en.yml` → `smart_match.quiz.*` |
| Display % rescale | [app/components/smart_match_card/component.rb](../../app/components/smart_match_card/component.rb) |

Original build plan (superseded in part by this work): [docs/smart-match-engine.md](../smart-match-engine.md)

## Scoring today

`Scorer#score_candidate` — [scorer.rb:23-25](../../app/services/smart_match/scorer.rb#L23-L25):

```
total = 0.70 × dense_similarity      # 1.0 - cosine_distance, floored at 0
      + 0.20 × attribute_bonus        # normalized 0..1, see below
      + 0.10 × distance_score         # 1.0 within 5mi, then linear decay to 0 at 100mi
```

`attribute_bonus` is four booleans, weighted and normalized by their sum
(`matching_rules.yml#attribute_weights`):

| Sub-signal | Weight | Source |
|---|---|---|
| `cause_match` | 5 | `causes_selected` ∩ org causes |
| `beneficiary_match` | 3 | `prefs_selected` ∩ org beneficiary subcategories |
| `scope_match` | 2 | `scope_of_work` vs `location_scope`/`travel_bucket` |
| `service_match` | 1 | `prefs_selected` ∩ location services |

Note `prefs_selected` is checked against **both** beneficiaries and services,
but `prefs` values are UI tokens (`free_sliding_scale`, `wheelchair_accessible`,
`multilingual`, …) that never equal a preset name. **In practice
`beneficiary_match` and `service_match` are near-permanently false.** The
attribute bonus is effectively `cause_match` + `scope_match` only.

## Hard filters today

All in `SimilarityQuery`:

- `organizations.active = true`, `locations.main = true`
- **local scope:** `locations.state_code = ?` (with an `ILIKE` fallback for
  un-backfilled rows), then `ST_DWithin` at the travel radius, expanding through
  `[5, 10, 25, 50]` until `min_results` (3) is met, else the whole state
- **national scope:** `scope_of_work IN ('National')`, broadening to include
  `International` if under `min_results`
- **international scope:** `scope_of_work = 'International'`, strict

`max_results` = 20.

## What `UserIntent` carries vs. what the quiz collects

`QuizNavigator::PARAM_SESSION_MAP` stores **20** answer keys. `UserIntent`
accepts **7**. Dropped on the floor:

`support_for`, `self_description`, `situation`, `donation_style`,
`giving_inspiration`, `donor_communities`, `impact_location`,
`donor_involvement`, `volunteer_involvement`, `volunteer_type`,
`volunteer_format`, `volunteer_time`, `age_range`, `gender_identity`,
`race_ethnicity`

Every one of the three lookup sheets (Row 6 / 34 / 49) scores answers from this
dropped set. Widening `UserIntent` is the unavoidable first step.

## Quiz answer tokens (authoritative values)

Extracted from the step partials. These are the keys any scoring table must
use — **not** the human labels in the CSV.

| Session key | Values |
|---|---|
| `user_type` | `service_seeker` `volunteer` `donor` |
| `support_for` | `myself` `someone_else` `organization` |
| `self_description` | `student` `veteran` `caregiver` `lgbtqia` `disability` `senior` `children_youth` `formerly_incarcerated` `economically_disadvantaged` `currently_unhoused` `mental_health` `substance_use` `health_issues` `business_nonprofit`\* `business_partner`\* `none` |
| `causes` | Cause names from `Organizations::Constants::CAUSES_AND_SERVICES` keys, plus `none` |
| `situation` | `urgent` `long_term` `exploring` `someone_else` `organization` |
| `city_selection` | `Nashville` `Los Angeles` `Atlantic City` `elsewhere` — display names, **not** slugs; they are written straight to `session[:smart_match_city]` and looked up in `city_centroids.yml` |
| `location_scope_choice` | `local` `national` `international` |
| `travel_bucket` | `nearby` `moderate` `far` `statewide` |
| `prefs` | `free_sliding_scale` `no_id_required` `multilingual` `lgbtqia_affirming` `wheelchair_accessible` `women_bipoc_led` `none` |
| `donation_style` | `general_donation` `specific_project` `goods_items` `recurring_giving` `just_exploring` |
| `giving_inspiration` | `personal_cause` `local_community` `real_impact` `underserved_communities` `values_aligned` `honor_memory` `discovering_ways` |
| `donor_communities` | `seniors` `veteran_military` `spanish_speaking` `bipoc` `disabilities` `lgbtqia` `children_family` `no_preference` |
| `impact_location` | `near_me` `specific_place` `anywhere` |
| `donor_involvement` | `one_time_donation` `deeper_involvement` `volunteer_events` `learn_updates` |
| `volunteer_involvement` | `volunteer_time` `attend_event` `business_partner` `just_exploring` |
| `volunteer_type` | `kids_seniors` `veterans_military` `spanish_speaking` `grassroots_bipoc` `behind_scenes` `accessible_virtual` `family_group` `no_preference` |
| `volunteer_format` | `in_person` `remote` `both` |
| `volunteer_time` | `one_time` `few_hours` `ongoing` `not_sure` |
| `age_range` | `under_18` `19_24` `25_34` `35_44` `45_54` `55_64` `over_65` `prefer_not_to_say` |
| `gender_identity` | `female` `male` `non_binary` `other` `prefer_not_to_say` |
| `race_ethnicity` | `asian` `black_african_american` `hispanic_latino` `middle_eastern_north_african` `native_american` `native_hawaiian` `white` `other` `prefer_not_to_say` |

\* `business_nonprofit` / `business_partner` only render when
`support_for == "organization"`.

## Sheet → session key mapping

| Lookup sheet | Scores this session key | Path |
|---|---|---|
| Row 6 | `self_description` (13 non-escape options) | Find Help |
| Row 34 | `donor_communities` (7 non-escape options) | Donor |
| Row 49 | `volunteer_type` (7 non-escape options) | Volunteer |

Counts line up exactly with the partials — the sheets are complete, no answer
is unmapped.

## Existing test coverage

`spec/services/smart_match/` — `scorer_spec`, `submission_processor_spec`,
`quiz_navigator_spec`, `quiz_step_config_spec`, `quiz_schema_consistency_spec`,
`embedding_client_spec`; plus `spec/queries/smart_match/similarity_query_spec`
and `spec/requests/smart_match/*`.

`quiz_schema_consistency_spec.rb` is the precedent for drift-guard specs: it
asserts two independently-encoded schemas agree. The scoring YAML needs the
same treatment against `Organizations::Constants`.
