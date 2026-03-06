# Smart Match Engine — Implementation Plan

## Goal

Build an AI-powered matching engine that pairs users (service seekers, volunteers, donors) with relevant nonprofits using BGE embeddings and cosine similarity, reusing Nathaly's proven matching logic while conforming to Telos architecture standards.

## Approach

Reuse Nathaly's core algorithm (multi-factor scoring: 70% embedding similarity + 20% attribute bonus + 10% distance), quiz flows, and configuration files — but restructure everything into proper Rails service objects, query objects, thin controllers, and pgvector-backed storage instead of JSON file-based embeddings. The Python embedding service (scaffolded in `embedding-service/`) handles only text-to-vector conversion; all matching logic stays in Rails using pgvector's cosine distance operator.

## Key Technical Decisions

- **pgvector over JSON matrix:** Store 1024-D embeddings in PostgreSQL instead of a 965MB JSON file. Enables `<=>` cosine distance queries directly in SQL, live updates when orgs change, and eliminates cold-loading the matrix into memory.
- **Containerized Python service:** Reuse the existing `embedding-service/` FastAPI scaffold (already defined as a Kamal accessory in `config/deploy.production.yml`). Add the BGE model. No conda, no shell-exec Python scripts.
- **Redis-backed session store:** Switch from Rails' default encrypted cookie store (4KB limit) to Redis-backed sessions. The cookie store cannot hold multi-step quiz answers (up to 36 cause selections for service seekers, preferences, location, free text) once encrypted. Redis is already running in both environments.
- **Three-model schema:** `OrganizationEmbedding`, `QuizSubmission`, `OrganizationMatch` — following the tech design doc.
- **BGE model choice:** Use `BAAI/bge-large-en-v1.5` (1024-D) for production. For staging (4GB droplet), use `BAAI/bge-base-en-v1.5` (768-D) unless the droplet is upgraded. The vector dimension must match the model — migrations use a configurable dimension. **Decision required before Phase 2:** standardize on one model or accept different dimensions per environment.

## Conventions

This plan follows the patterns established in the existing codebase:

- **Services** inherit from `ApplicationService` and expose `self.call(...)` (see `app/services/application_service.rb`).
- **Query objects** go in `app/queries/` and follow the `Locations::GeolocationQuery` class-method pattern.
- **ViewComponents** use the `Namespace::Component` pattern (e.g., `SmartMatchCard::Component` at `app/components/smart_match_card/component.rb`), inheriting from `ApplicationViewComponent`.
- **Views** use `.html.erb` for all new Smart Match templates.
- **Authorization** uses Pundit (not ActionPolicy).
- **HTTP client:** Use `Net::HTTP` from stdlib for the embedding client (no new gem dependency). If complexity grows, add Faraday later.

---

## Phase 0 — Prerequisites

Exit criteria: Data mappings validated, session store switched, embedding service ready on staging.

### Session Store

- `config/initializers/session_store.rb` (new) — Switch to Redis-backed sessions:
  ```ruby
  Rails.application.config.session_store :redis_store,
    servers: [ENV.fetch("REDIS_URL", "redis://localhost:6379/1")],
    expire_after: 1.day,
    key: "_giving_connection_session"
  ```
- `Gemfile` (modify) — Add `gem "redis-session-store"` (or `gem "redis-actionpack"`).

### Data Validation

- Validate `matching_rules.yml` cause names and NTEE codes against production `causes` and `services` tables. Document any mismatches and update the YAML before proceeding to Phase 1.
- Validate `city_centroids.yml` cities against production `locations` table city values.
- Compare Nathaly's branch org data field references against current `Organization` schema (verified fields: `name`, `mission_statement_en`, `vision_statement_en`, `tagline_en`, causes association, beneficiary_subcategories association, locations association).

### Staging Embedding Service

- `config/deploy.staging.yml` (modify) — Add embedding service accessory (currently only defined in production config):
  ```yaml
  accessories:
    embedding-api:
      image: ghcr.io/teloslabs/gc-embedding-api
      host: 138.197.90.4
      port: "127.0.0.1:8000:8000"
      options:
        memory: 1g
      env:
        clear:
          PYTHONUNBUFFERED: "1"
  ```
- `config/deploy.production.yml` (modify) — Add memory limit to embedding accessory:
  ```yaml
  accessories:
    embedding-api:
      # ... existing config ...
      options:
        memory: 2.5g
  ```

---

## Phase 1 — UI & Data Flow Foundation

Exit criteria: A user completes the quiz end-to-end and the backend receives structured answers.

### Routes

- `config/routes.rb` (modify) — Add smart match routes using a RESTful namespace:
  ```ruby
  namespace :smart_match do
    root to: "landing#show"              # GET /smart_match
    resource :quiz, only: [:show, :update] # GET/PUT /smart_match/quiz
    resources :results, only: [:index]     # GET /smart_match/results
  end
  ```
  Feedback routes deferred to Phase 3 (when the model exists).

### Controllers

- `app/controllers/smart_match/landing_controller.rb` (new) — Single `show` action rendering the landing page. Skips `authenticate_user!`.
- `app/controllers/smart_match/quizzes_controller.rb` (new) — Thin controller (~30 lines). `show` renders current quiz step, `update` processes step submission and advances. Delegates navigation to `SmartMatch::QuizNavigator`. Stores quiz progress in session. Skips `authenticate_user!`.
- `app/controllers/smart_match/results_controller.rb` (new) — Single `index` action. Initially renders a placeholder. Fleshed out in Phase 2. Skips `authenticate_user!`.

### Services

- `app/services/smart_match/quiz_navigator.rb` (new) — Inherits `ApplicationService`. `call` method handles quiz step progression, answer storage in session, step count by user type, and navigation (next/back). Extracted from Nathaly's controller methods `get_total_steps`, step processing logic, and answer parsing.

### Models

- `app/models/user_intent.rb` (new) — ActiveModel (not ActiveRecord). Includes `ActiveModel::Model` and `ActiveModel::Validations`. Port of Nathaly's UserIntent. Represents structured quiz answers: `state`, `city`, `travel_bucket`, `user_type`, `causes_selected`, `prefs_selected`, `language_input`.

### Views

All views use `.html.erb`:

- `app/views/smart_match/landing/show.html.erb` (new) — Landing page. Port from Nathaly's `views/index.html.erb`.
- `app/views/smart_match/quizzes/show.html.erb` (new) — Quiz container with Turbo Frame for step navigation. Port from Nathaly's `views/quiz/quiz.html.erb`.
- `app/views/smart_match/quizzes/_service_seeker_path.html.erb` (new) — Seeker quiz flow (36 causes). Port from Nathaly's `components/paths/`.
- `app/views/smart_match/quizzes/_volunteer_path.html.erb` (new) — Volunteer quiz flow (14 causes).
- `app/views/smart_match/quizzes/_donor_path.html.erb` (new) — Donor quiz flow (14 causes).
- `app/views/smart_match/results/index.html.erb` (new) — Results display page. Placeholder until Phase 2.

### Stimulus

- `app/javascript/controllers/smart_match_quiz_controller.js` (new) — Quiz UI interaction: step navigation, multi-select toggles, progress bar updates, form submission. Port from Nathaly's 822-line controller but remove layout-fixing code and reduce to ~200 lines following Stimulus conventions (targets, values, actions).

### Configuration

- `config/matching_rules.yml` (new) — Port from Nathaly's branch, **after** Phase 0 data validation. Contains: allowed states, radius by travel bucket, cause synonyms with NTEE mappings, attribute weights, quiz mappings, scoring behavior flags.
- `config/city_centroids.yml` (new) — Port from Nathaly's branch, after validation. City center coordinates for NJ, CA, TN.

### Styling

- `app/assets/stylesheets/components/_smart_match.scss` (new) — Port from Nathaly's SCSS. Adapt to existing design system conventions.

---

## Phase 2 — Core Matching Engine

Exit criteria: Results filtered by state/city/cause, radius expansion works, results returned in < 1 second.

### Database

- `db/migrate/XXXX_enable_pgvector.rb` (new) — `enable_extension 'vector'` in PostgreSQL.
- `db/migrate/XXXX_create_organization_embeddings.rb` (new) — Table: `organization_embeddings`
  - `organization_id` (references, unique index)
  - `embedding` (vector(1024))
  - `text_snapshot` (text)
  - `metadata` (jsonb)
  - `created_at`, `updated_at`
- `db/migrate/XXXX_create_quiz_submissions.rb` (new) — Table: `quiz_submissions`
  - `user_id` (nullable references, indexed)
  - `session_id` (string, indexed)
  - `answers` (jsonb)
  - `user_type` (string)
  - `embedding` (vector(1024))
  - `text_snapshot` (text)
  - `created_at`, `updated_at`
- `db/migrate/XXXX_create_organization_matches.rb` (new) — Table: `organization_matches`
  - `quiz_submission_id` (references)
  - `organization_id` (references)
  - `score` (decimal)
  - `score_breakdown` (jsonb — `dense_similarity`, `attribute_bonus`, `distance_score`)
  - `rank` (integer)
  - `created_at`
  - Composite unique index on `(quiz_submission_id, organization_id)`
- `db/migrate/XXXX_add_vector_index_to_organization_embeddings.rb` (new) — Add HNSW index on the `embedding` column for fast nearest-neighbor queries once data is populated.

### Gem Dependencies

- `Gemfile` (modify) — Add `gem "neighbor"` for pgvector Rails integration. Provides `has_neighbors :embedding` declarations, `.nearest_neighbors` scope, and handles vector type casting.

### Models

- `app/models/organization_embedding.rb` (new) — `belongs_to :organization`. `has_neighbors :embedding`. Validates presence of `embedding` and `text_snapshot`. Method `stale?` compares `text_snapshot` against current org data.
- `app/models/quiz_submission.rb` (new) — `belongs_to :user, optional: true`. `has_many :organization_matches, dependent: :destroy`. `has_neighbors :embedding`. Stores quiz answers as JSONB.
- `app/models/organization_match.rb` (new) — `belongs_to :quiz_submission`. `belongs_to :organization`. Stores final score, score breakdown (jsonb), and rank.

### Python Embedding Service

- `embedding-service/main.py` (modify) — Replace placeholder with real BGE implementation:
  - Load `BAAI/bge-large-en-v1.5` model on startup via a lifespan event.
  - `POST /embed` endpoint: accepts `{"text": "..."}`, returns `{"vector": [...]}` (1024-D).
  - `POST /embed_batch` endpoint: accepts `{"texts": ["...", ...]}`, returns `{"vectors": [[...], ...]}`. Batch size capped at 64.
  - Explicit tokenization and truncation to 512 tokens before encoding (don't rely on silent truncation).
  - Health check at `GET /health` returns model loaded status.
- `embedding-service/requirements.txt` (modify) — Pin versions:
  ```
  fastapi==0.115.6
  uvicorn==0.34.0
  sentence-transformers==3.3.1
  torch==2.5.1
  ```
- `embedding-service/Dockerfile` (modify) — Pre-download model weights during build:
  ```dockerfile
  RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('BAAI/bge-large-en-v1.5')"
  ```
  This avoids ~30s cold start on first request after container restart.

### Services

- `app/services/smart_match/embedding_client.rb` (new) — Inherits `ApplicationService`. HTTP client using `Net::HTTP` wrapping the Python service. `call(text:)` POSTs to `http://127.0.0.1:8000/embed`, returns vector array. Class method `embed_batch(texts:)` for bulk operations. Includes 5s timeout, 1 retry. Reads host/port from `ENV["EMBEDDING_SERVICE_URL"]` (default `http://127.0.0.1:8000`). Raises `SmartMatch::EmbeddingUnavailableError` on failure.
- `app/services/smart_match/organization_text_builder.rb` (new) — Inherits `ApplicationService`. `call(organization:)` builds the text blob from DB fields: name, `mission_statement_en`, `vision_statement_en`, `tagline_en`, causes (names joined), beneficiary subcategories (names joined), main location city/state. Truncates at **1500 chars** (safe margin for BGE's 512-token limit). Returns `nil` if all embeddable fields are blank (org is skipped).
- `app/services/smart_match/quiz_text_builder.rb` (new) — Inherits `ApplicationService`. `call(user_intent:)` converts UserIntent into weighted text for embedding. Multiplies primary causes x3, secondary causes x2, location x1, preferences x1. Expands causes using synonyms from `matching_rules.yml`. Truncates at **1500 chars**.
- `app/services/smart_match/quiz_to_user_intent_converter.rb` (new) — Inherits `ApplicationService`. Port from Nathaly's `quiz_to_user_intent_converter.rb` (332 lines). `call(session_answers:, user_type:)` converts raw session hash into a `UserIntent` object.
- `app/services/smart_match/scorer.rb` (new) — Inherits `ApplicationService`. Handles the non-SQL parts of matching: attribute bonus scoring from `matching_rules.yml` weights, distance scoring, and combining scores: `0.70 * dense + 0.20 * attribute + 0.10 * distance`. `call(candidates:, user_intent:)` accepts pre-filtered candidates from the query layer and returns ranked results.
- `app/services/smart_match/submission_processor.rb` (new) — Inherits `ApplicationService`. Orchestrates the full flow: `call(session_answers:, user_type:, session_id:, user: nil)`:
  1. Converts to UserIntent via `QuizToUserIntentConverter`
  2. Builds quiz text via `QuizTextBuilder`
  3. Calls `EmbeddingClient` for the user vector
  4. Creates `QuizSubmission`
  5. Runs `SmartMatch::SimilarityQuery` for candidate retrieval
  6. Scores candidates via `Scorer`
  7. Creates `OrganizationMatch` records
  8. Returns ranked results

### Query Objects

- `app/queries/smart_match/similarity_query.rb` (new) — Handles the SQL-heavy matching pipeline. Class method interface following `Locations::GeolocationQuery` pattern:
  ```ruby
  module SmartMatch
    class SimilarityQuery
      class << self
        def call(embedding:, state:, coordinates:, radius_miles: 5)
          # 1. Filter organization_embeddings by state (join organizations -> locations)
          # 2. Distance filter using PostGIS ST_DWithin (reuse Geo.point pattern)
          # 3. Progressive radius expansion if < 3 results (5 -> 10 -> 25 -> 50 miles)
          # 4. If still < 1 after 50 miles, fall back to state-wide
          # 5. Cosine similarity via neighbor gem's .nearest_neighbors
          # Returns: array of {organization_embedding:, cosine_distance:, distance_miles:}
        end
      end
    end
  end
  ```

### Background Jobs

- `app/jobs/smart_match/embed_organization_job.rb` (new) — Accepts `organization_id`. Delegates to `OrganizationTextBuilder` then `EmbeddingClient`. Creates/updates `OrganizationEmbedding`. Handles missing org gracefully (log and return).
- `app/jobs/smart_match/embed_all_organizations_job.rb` (new) — Iterates all active organizations in batches of 50. Calls `EmbeddingClient.embed_batch` per batch. Creates/updates `OrganizationEmbedding` records. ~19 HTTP calls instead of 928.

### Callbacks

- `app/models/organization.rb` (modify) — Add:
  ```ruby
  has_one :organization_embedding, dependent: :destroy

  after_commit :schedule_embedding_update, on: [:create, :update]

  private

  EMBEDDING_FIELDS = %w[name mission_statement_en vision_statement_en tagline_en].freeze

  def schedule_embedding_update
    return unless new_record? || previous_changes.keys.intersect?(EMBEDDING_FIELDS)
    SmartMatch::EmbedOrganizationJob.perform_later(id)
  end
  ```
  **Note:** Association changes (causes, beneficiaries) do NOT trigger `after_commit` on the parent Organization. Add a separate callback on `OrganizationCause`:
- `app/models/organization_cause.rb` (modify) — Add:
  ```ruby
  after_commit :schedule_org_embedding_update, on: [:create, :destroy]

  private

  def schedule_org_embedding_update
    SmartMatch::EmbedOrganizationJob.perform_later(organization_id)
  end
  ```

### Controller Updates

- `app/controllers/smart_match/results_controller.rb` (modify) — Flesh out `index` action: call `SubmissionProcessor`, assign results to instance variables. Handle `SmartMatch::EmbeddingUnavailableError` with a user-friendly error page.

### View Components

- `app/components/smart_match_card/component.rb` (new) — Inherits `ApplicationViewComponent`. Accepts organization and match data. Displays: org name, match percentage, cause tags, location, logo.
- `app/components/smart_match_card/component.html.erb` (new) — Template for the card. Port from Nathaly's smart_match_card components.

### Views

- `app/views/smart_match/results/index.html.erb` (modify) — Render `SmartMatchCard::Component` for each result. Show match percentage. Show "no perfect match" message when top score is below threshold.

### Rake Task

- `lib/tasks/smart_match.rake` (new) — `smart_match:embed_all` task to seed all organization embeddings using the batch flow. Used during initial setup and after data migrations.

### Environment Variables

- `EMBEDDING_SERVICE_URL` — Add to `config/deploy.yml` `env.clear`:
  ```yaml
  EMBEDDING_SERVICE_URL: "http://127.0.0.1:8000"
  ```

---

## Phase 3 — Persistence & UX Enhancements

Exit criteria: Users can return to previous results; users can like/dislike matches.

### Database

- `db/migrate/XXXX_create_recommendation_feedbacks.rb` (new) — Table: `recommendation_feedbacks`
  - `user_id` (nullable references)
  - `organization_id` (references)
  - `quiz_submission_id` (references)
  - `feedback_type` (string — "like" or "dislike")
  - `session_id` (string)
  - Unique index on `(session_id, organization_id)`

### Models

- `app/models/recommendation_feedback.rb` (new) — `belongs_to :user, optional: true`. `belongs_to :organization`. `belongs_to :quiz_submission`. Validates inclusion of `feedback_type` in `%w[like dislike]`.

### Routes

- `config/routes.rb` (modify) — Add feedback route inside smart_match namespace:
  ```ruby
  namespace :smart_match do
    # ... existing routes ...
    resources :feedbacks, only: [:create]
  end
  ```

### Controllers

- `app/controllers/smart_match/feedbacks_controller.rb` (new) — Single `create` action. Creates `RecommendationFeedback` record. Responds with Turbo Stream to update the button state.

### Features

- **Resume quiz:** `SmartMatch::QuizzesController#show` checks session for existing progress and resumes from last step. Already handled by session storage in Phase 1.
- **View previous results:** `SmartMatch::ResultsController#index` checks for existing `QuizSubmission` (by `user_id` or `session_id`) and shows cached results without re-running the engine.
- **Reset quiz:** Add `destroy` action to `SmartMatch::QuizzesController` that clears session data and redirects to landing.
- **Result explanations:** `OrganizationMatch#score_breakdown` JSONB already stores component scores. The results view displays "High match on: Cause Area (85%), Location (92%)" derived from the breakdown.

### Tracking/Metrics

- `app/services/smart_match/analytics_tracker.rb` (new) — Inherits `ApplicationService`. Tracks: quiz completions, confirmed matches (user clicks through to org), time-to-match (submission to results rendered). Writes to Rails logger with structured tags for log aggregation.

---

## Edge Cases

| Scenario | Handling |
|---|---|
| No organizations in area | Progressive radius expansion: 5 -> 10 -> 25 -> 50 miles. If still none after 50, return state-wide results with "No nearby organizations found, showing closest matches" message. |
| Embedding service down | `EmbeddingClient` raises `SmartMatch::EmbeddingUnavailableError`. Results controller rescues it and renders "Smart Match is temporarily unavailable" page. |
| Organization with no embeddable text | `OrganizationTextBuilder` returns `nil`. Job logs a warning and skips the org. |
| Stale embeddings | `OrganizationEmbedding#stale?` compares `text_snapshot` to current text. `after_commit` on Organization and `OrganizationCause` triggers re-embedding only when relevant fields or associations change. |
| Long quiz/org text | Both text builders truncate at 1500 chars. Python service explicitly tokenizes and truncates to 512 tokens as a safety net. |
| Concurrent quiz sessions | Redis-backed session store handles this naturally; each browser session is independent. |
| User not logged in | `quiz_submission.user_id` is nullable; `session_id` tracks anonymous users. |
| "Too few results" threshold | `SimilarityQuery` expands radius when fewer than 3 results are returned. Always returns at least 1 result even if low score. |

---

## Testing Strategy

### Request Specs

- `spec/requests/smart_match/landing_spec.rb` (new) — Landing page renders, auth skipped.
- `spec/requests/smart_match/quizzes_spec.rb` (new) — Quiz step navigation, session persistence across steps, step submission.
- `spec/requests/smart_match/results_spec.rb` (new) — Results with mocked `SubmissionProcessor`, embedding service unavailable handling.
- `spec/requests/smart_match/feedbacks_spec.rb` (new) — Feedback creation (Phase 3).

### Service Specs

- `spec/services/smart_match/quiz_navigator_spec.rb` (new) — Step progression by user type, answer storage, total steps.
- `spec/services/smart_match/organization_text_builder_spec.rb` (new) — Text construction, truncation at 1500 chars, nil handling for blank orgs.
- `spec/services/smart_match/quiz_text_builder_spec.rb` (new) — Weighting (cause x3, etc.), synonym expansion, truncation, text construction by user type.
- `spec/services/smart_match/quiz_to_user_intent_converter_spec.rb` (new) — Conversion for each user type. Edge cases: missing fields, invalid values.
- `spec/services/smart_match/embedding_client_spec.rb` (new) — Stub HTTP calls. Test success, timeout, service unavailable responses, `EmbeddingUnavailableError` raised correctly.
- `spec/services/smart_match/scorer_spec.rb` (new) — Score calculation, weight application, ranking order, minimum 1 result guarantee.
- `spec/services/smart_match/submission_processor_spec.rb` (new) — Full flow integration with mocked embedding client.

### Query Specs

- `spec/queries/smart_match/similarity_query_spec.rb` (new) — State filtering, distance filtering via PostGIS, radius expansion, cosine similarity ordering. Requires factories with real vector data.

### Model Specs

- `spec/models/organization_embedding_spec.rb` (new) — Validations, `stale?` method, neighbor gem scopes.
- `spec/models/quiz_submission_spec.rb` (new) — Validations, associations, JSONB accessor behavior.
- `spec/models/organization_match_spec.rb` (new) — Validations, associations, score_breakdown access.
- `spec/models/user_intent_spec.rb` (new) — ActiveModel validations for all required fields.

### Job Specs

- `spec/jobs/smart_match/embed_organization_job_spec.rb` (new) — Enqueues correctly, handles missing org gracefully, creates/updates embedding.
- `spec/jobs/smart_match/embed_all_organizations_job_spec.rb` (new) — Batches correctly, calls embed_batch, handles partial failures.

### Factories

- `spec/factories/organization_embeddings.rb` (new) — Factory with random 1024-D vector.
- `spec/factories/quiz_submissions.rb` (new) — Factory with sample answers JSONB and vector.
- `spec/factories/organization_matches.rb` (new) — Factory with score and breakdown.

### Setup

- Test database needs the `vector` extension enabled. Add to `spec/support/database.rb` or ensure `db/schema.rb` includes `enable_extension "vector"`.
- The `neighbor` gem handles vector type casting in tests automatically.

---

## Risks

### 1. BGE model memory on staging (HIGH)

The staging droplet is 4GB with self-hosted PostgreSQL, Redis, and Rails. BGE-large needs ~2GB. **This will not fit.** Options:
- **(a)** Use `bge-base-en-v1.5` (768-D, ~500MB) on staging only. Requires different vector dimensions per environment.
- **(b)** Upgrade the staging droplet to 8GB (~$48/mo).
- **(c)** Skip the embedding service on staging and mock it. Limits staging testing.

**Recommendation:** Option (b) is simplest. Option (a) adds complexity for minimal savings.

### 2. Cold start latency (MEDIUM)

First embedding request after container restart loads the model (~30s). Mitigated by pre-downloading weights in the Docker build. But if the container OOM-restarts, there's a 30s window of unavailability. The health check should report unhealthy until the model is loaded.

### 3. Nathaly's branch divergence (MEDIUM)

Her branch is based on an older main. Quiz view HTML and matching rules may reference org data fields that have changed. Phase 0 data validation mitigates this, but expect some mapping updates.

### 4. Association-change re-embedding (LOW)

The `after_commit` on `OrganizationCause` will trigger a re-embed job whenever a cause is added or removed. If an admin bulk-updates causes for many orgs, this could enqueue hundreds of jobs. The embedding service handles one at a time. Consider debouncing or deduplication in Sidekiq (e.g., `sidekiq-unique-jobs`).

### 5. pgvector index tuning (LOW)

HNSW index parameters (`m`, `ef_construction`) affect recall vs. speed. With ~928 orgs, the default parameters are fine. Revisit if the org count grows past 10,000.

### 6. Embedding service availability (LOW)

If the Python container crashes, the matching flow fails. The `EmbeddingUnavailableError` handling provides graceful degradation (shows error page). For higher reliability, add a Kamal health check that auto-restarts the container, and consider a circuit breaker in `EmbeddingClient` if failures are frequent.

---

## File Summary

### New Files

| Phase | Path | Type |
|---|---|---|
| 0 | `config/initializers/session_store.rb` | Initializer |
| 0 | `config/deploy.staging.yml` (modify) | Kamal config |
| 0 | `config/deploy.production.yml` (modify) | Kamal config |
| 1 | `app/controllers/smart_match/landing_controller.rb` | Controller |
| 1 | `app/controllers/smart_match/quizzes_controller.rb` | Controller |
| 1 | `app/controllers/smart_match/results_controller.rb` | Controller |
| 1 | `app/services/smart_match/quiz_navigator.rb` | Service |
| 1 | `app/models/user_intent.rb` | ActiveModel |
| 1 | `app/views/smart_match/landing/show.html.erb` | View |
| 1 | `app/views/smart_match/quizzes/show.html.erb` | View |
| 1 | `app/views/smart_match/quizzes/_service_seeker_path.html.erb` | View |
| 1 | `app/views/smart_match/quizzes/_volunteer_path.html.erb` | View |
| 1 | `app/views/smart_match/quizzes/_donor_path.html.erb` | View |
| 1 | `app/views/smart_match/results/index.html.erb` | View |
| 1 | `app/javascript/controllers/smart_match_quiz_controller.js` | Stimulus |
| 1 | `config/matching_rules.yml` | Config |
| 1 | `config/city_centroids.yml` | Config |
| 1 | `app/assets/stylesheets/components/_smart_match.scss` | Stylesheet |
| 2 | `db/migrate/XXXX_enable_pgvector.rb` | Migration |
| 2 | `db/migrate/XXXX_create_organization_embeddings.rb` | Migration |
| 2 | `db/migrate/XXXX_create_quiz_submissions.rb` | Migration |
| 2 | `db/migrate/XXXX_create_organization_matches.rb` | Migration |
| 2 | `db/migrate/XXXX_add_vector_index_to_organization_embeddings.rb` | Migration |
| 2 | `app/models/organization_embedding.rb` | Model |
| 2 | `app/models/quiz_submission.rb` | Model |
| 2 | `app/models/organization_match.rb` | Model |
| 2 | `app/services/smart_match/embedding_client.rb` | Service |
| 2 | `app/services/smart_match/organization_text_builder.rb` | Service |
| 2 | `app/services/smart_match/quiz_text_builder.rb` | Service |
| 2 | `app/services/smart_match/quiz_to_user_intent_converter.rb` | Service |
| 2 | `app/services/smart_match/scorer.rb` | Service |
| 2 | `app/services/smart_match/submission_processor.rb` | Service |
| 2 | `app/queries/smart_match/similarity_query.rb` | Query |
| 2 | `app/jobs/smart_match/embed_organization_job.rb` | Job |
| 2 | `app/jobs/smart_match/embed_all_organizations_job.rb` | Job |
| 2 | `app/components/smart_match_card/component.rb` | ViewComponent |
| 2 | `app/components/smart_match_card/component.html.erb` | ViewComponent |
| 2 | `lib/tasks/smart_match.rake` | Rake task |
| 3 | `db/migrate/XXXX_create_recommendation_feedbacks.rb` | Migration |
| 3 | `app/models/recommendation_feedback.rb` | Model |
| 3 | `app/controllers/smart_match/feedbacks_controller.rb` | Controller |
| 3 | `app/services/smart_match/analytics_tracker.rb` | Service |

### Modified Files

| Phase | Path | Change |
|---|---|---|
| 0 | `Gemfile` | Add `redis-session-store` |
| 1 | `config/routes.rb` | Add `smart_match` namespace routes |
| 2 | `Gemfile` | Add `neighbor` |
| 2 | `app/models/organization.rb` | Add `has_one :organization_embedding`, `after_commit` |
| 2 | `app/models/organization_cause.rb` | Add `after_commit` for re-embedding |
| 2 | `embedding-service/main.py` | Real BGE implementation |
| 2 | `embedding-service/requirements.txt` | Add `torch` |
| 2 | `embedding-service/Dockerfile` | Pre-download model weights |
| 2 | `config/deploy.yml` | Add `EMBEDDING_SERVICE_URL` env var |
