# CLAUDE.md — Giving Connection

Project-wide instructions for AI coding agents (Claude Code, Cursor, Copilot, Codex, etc.).
Read this **before** making changes. The conventions here are what reviewers will check
against; following them up front saves a round trip.

If anything in this file conflicts with what you observe in the codebase, **trust the code**
and flag the drift so this file can be updated.

---

## What this app is

Giving Connection matches nonprofits with community members in Nashville and Atlantic City.
Active work right now centers on the **Smart Match** feature: a quiz → embedding → vector
similarity pipeline that recommends organizations to users.

Stack:

- Ruby **3.4.8** (see [.ruby-version](.ruby-version))
- Rails **7.2.x**
- Postgres + **PostGIS** + **pgvector**
- Redis + Sidekiq (`< 7`)
- Hotwire (Turbo + Stimulus), `view_component`, Slim, Tailwind
- `jsbundling-rails` + `cssbundling-rails`, Node **20.17.0** (see [.nvmrc](.nvmrc))
- Devise, Pundit, Mobility (i18n), Administrate (admin panel)
- Python FastAPI sidecar for embeddings in [embedding-service/](embedding-service/)
- Deployment via Kamal

---

## Before you start

1. **Read the diff target.** If you're working on a branch, `git diff main...HEAD --stat`
   first so you understand scope.
2. **Find the pattern before inventing one.** This codebase has well-established patterns
   for services, jobs, queries, policies, decorators, view components, and specs. Search
   for an analogous existing file and copy its shape rather than introducing a new style.
3. **Don't grow `.rubocop_todo.yml`.** It exists to grandfather old violations, not absorb
   new ones. New code must pass `.rubocop/strict.yml`.
4. **Never edit `db/schema.rb` by hand.** Write a migration; let Rails regenerate it.

---

## Architectural conventions

### Service objects — `app/services/`

All services inherit from `ApplicationService` and expose a single `.call` class method
that forwards to `#call` on an instance:

```ruby
# app/services/application_service.rb
class ApplicationService
  def self.call(...)
    new(...).call
  end
end
```

Pattern in use (see [app/services/smart_match/submission_processor.rb](app/services/smart_match/submission_processor.rb)):

- `# frozen_string_literal: true` at top
- Namespaced module for features (`module SmartMatch`)
- Keyword-arg `initialize`
- `attr_reader` for inputs
- One public `#call`; everything else `private`
- Return a plain hash or a result value, not the service instance

When adding a new service, mirror an existing one in the same domain.

### Jobs — `app/jobs/`

- Inherit from `ApplicationJob`
- Namespaced under feature module (e.g. `SmartMatch::EmbedOrganizationJob`)
- Explicit `queue_as :default` (or another named queue)
- **Always guard against missing records** with `find_by(id:)` + log + return — jobs
  must not raise on stale IDs. Example: [app/jobs/smart_match/embed_organization_job.rb](app/jobs/smart_match/embed_organization_job.rb)
- Log with `Rails.logger.warn("[FeatureName] message")` — bracketed prefix is the convention

### Queries — `app/queries/`

Encapsulate complex AR scopes. Inherit pattern from
[app/queries/application_query.rb](app/queries/application_query.rb) and mirror
[app/queries/smart_match/similarity_query.rb](app/queries/smart_match/similarity_query.rb)
(class-method `.call`, private helpers, constants for magic numbers).

### Models — `app/models/`

- Inherit from `ApplicationRecord`
- Use `pg_search` for full-text search where appropriate
- Use `mobility` for translatable attributes — do **not** hand-roll translation columns
- Concerns live in `app/models/concerns/`
- For has_many through join tables, follow the existing `OrganizationCause` / `OrganizationBeneficiary` style

### Controllers — `app/controllers/`

- Inherit from `ApplicationController`
- Use **Pundit** for authorization (`authorize @record`); policies in `app/policies/`
- Namespace feature controllers under a module + folder (e.g. `SmartMatch::QuizzesController` lives in `app/controllers/smart_match/quizzes_controller.rb`)
- Strong params via private methods

### View components — `app/components/`

- Inherit from `ApplicationViewComponent` (which inherits `ViewComponent::Base`)
- One folder per component containing `_component.rb` and `_component.html.{erb,slim}`
- Prefer extracting a component over a partial when there's any logic

### Views

- Mixed Slim and ERB are both fine — match the surrounding feature.
- Translations: every user-facing string goes through `t(".key")` and lives in
  [config/locales/en.yml](config/locales/en.yml)
- Inline SVGs via `inline_svg_tag`

### Decorators — `app/decorators/`

Use [Draper](https://github.com/drapergem/draper) for presentation logic.
Inherit from `ApplicationDecorator`. Don't put view logic in models.

---

## Smart Match feature specifics

Detailed design lives in [docs/smart-match-engine.md](docs/smart-match-engine.md). Read it
before changing anything in:

- `app/services/smart_match/`
- `app/jobs/smart_match/`
- `app/queries/smart_match/`
- `app/controllers/smart_match/`
- `app/models/{organization_embedding,organization_match,quiz_submission,user_intent}.rb`
- [config/matching_rules.yml](config/matching_rules.yml) — scoring weights, radii, etc.
- [config/city_centroids.yml](config/city_centroids.yml)
- [embedding-service/](embedding-service/) — Python FastAPI sidecar; the wire format is
  load-bearing, do not change request/response shape on one side without updating the other

Config is loaded via `SmartMatch::Config` ([app/services/smart_match/config.rb](app/services/smart_match/config.rb))
which memoizes YAML. If you add a new tunable, put it in `matching_rules.yml` rather than
hardcoding it.

---

## Testing

- **RSpec** for everything; no Minitest. Spec helper: [spec/rails_helper.rb](spec/rails_helper.rb)
- **FactoryBot** factories live in `spec/factories/`. Use `create(:thing)` / `build(:thing)`; do not use fixtures.
- **Headless system specs** are the default. Run `HEADLESS=false bundle exec rspec` to see the browser.
- Spec layout mirrors `app/`: a service at `app/services/smart_match/scorer.rb` has its spec at `spec/services/smart_match/scorer_spec.rb`.
- Add `# frozen_string_literal: true` to spec files.
- Keep `RSpec.describe ClassName do` at the top; describe public methods as `describe ".call"` (class) or `describe "#method"` (instance).
- **Never commit `:focus`, `pry`/`binding.pry`, or `puts`** — `.rubocop/strict.yml` enforces this and CI will fail.
- Use `find_each` for batches, not `each` — also enforced strictly.
- `rspec-retry` is enabled for flaky system specs; don't rely on it to mask real flakiness.

When you add a new model/service/job/query, **add a spec**. CI runs `--fail-fast`, so an
untested change tends to surface later in unrelated builds.

---

## Linting, formatting, security

This project uses **Standard Ruby** via RuboCop. Configuration:

- [.rubocop.yml](.rubocop.yml) — entry point; inherits Standard + custom + strict + todo
- [.rubocop/strict.yml](.rubocop/strict.yml) — non-negotiable cops (no debugger, no focused specs, no `puts`, `find_each`, `uniq.pluck` order)
- [.rubocop_todo.yml](.rubocop_todo.yml) — grandfathered violations; **don't add to this**

Run before declaring done:

```bash
bundle exec rubocop            # full lint
bundle exec rubocop -a         # auto-fix safe offenses
bundle exec brakeman -w3       # security scan (CI gate)
bundle exec bundle-audit check --update  # gem CVEs (CI gate)
bundle exec rspec              # tests
```

A convenience wrapper is at [bin/check](bin/check) — prefer it.

CI ([.github/workflows/ruby-ci.yml](.github/workflows/ruby-ci.yml)) runs Rubocop, Brakeman,
bundle-audit, and the full RSpec suite (with PostGIS + pgvector). All four must pass.

---

## What NOT to do

- **Don't edit `db/schema.rb`** — write a migration in `db/migrate/`.
- **Don't add entries to `.rubocop_todo.yml`** for new code. Fix the violation instead.
- **Don't introduce new dependencies** without a clear justification in the PR description. Prefer stdlib / existing gems.
- **Don't bypass Pundit** in controllers — `authorize` every action that touches a model the user owns.
- **Don't write translatable strings as literals** in views — use `t(".key")`.
- **Don't mock at the wrong boundary** — for the smart-match pipeline, mock `EmbeddingClient`/HTTP, not AR models. See [spec/services/smart_match/submission_processor_spec.rb](spec/services/smart_match/submission_processor_spec.rb).
- **Don't use `binding.pry`, `puts`, or `it.focus`** in committed code — CI fails.
- **Don't write code comments that just restate what the code does.** Comment only when the *why* is non-obvious.
- **Don't `git add .` blindly.** Stage specific files; this repo has `.env`, dumps, and credentials nearby.
- **Don't change request/response shapes between Rails and [embedding-service/](embedding-service/)** unilaterally — both sides ship together.

---

## File-path conventions (quick reference)

| Concern | Location |
| --- | --- |
| Service object | `app/services/<feature>/<name>.rb` (subclass `ApplicationService`) |
| Background job | `app/jobs/<feature>/<name>_job.rb` (subclass `ApplicationJob`) |
| Complex AR query | `app/queries/<feature>/<name>_query.rb` |
| Authorization | `app/policies/<model>_policy.rb` (subclass `ApplicationPolicy`) |
| Presentation | `app/decorators/<model>_decorator.rb` (subclass `ApplicationDecorator`) |
| Reusable UI | `app/components/<name>/<name>_component.rb` + template |
| Admin pages | `app/dashboards/` (Administrate) |
| Translations | `config/locales/en.yml` |
| Migrations | `db/migrate/<timestamp>_<snake_name>.rb` |
| Specs | mirror app path under `spec/` |
| Factories | `spec/factories/<table_name>.rb` |

---

## How to run things

```bash
bin/setup                 # one-time: deps + DB
bin/dev                   # start Rails + JS + CSS watchers
bundle exec rspec         # tests
bin/check                 # rubocop + brakeman + bundle-audit + rspec
```

Docker workflow lives in [.dockerdev/](.dockerdev/) via `dip`.

---

## When you're done with a change

Before saying "done":

1. `bin/check` is green locally (or you've stated explicitly what's failing and why).
2. New code has a spec; coverage hasn't dropped.
3. `.rubocop_todo.yml` has not grown.
4. No `binding.pry`, `puts`, `it.focus`, or stray `console.log`.
5. Any new user-facing string is in `config/locales/en.yml`, not hardcoded.
6. If you touched `embedding-service/`, the Rails-side caller still matches the wire format.
7. PR description follows [.github/pull_request_template.md](.github/pull_request_template.md) and links the ClickUp ticket.

If something on this list can't be done, **say so explicitly** in the response rather than
silently skipping it.
