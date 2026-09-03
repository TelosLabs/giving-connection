# Deployment Runbook (Kamal → DigitalOcean)

How to deploy Giving Connection to **staging** and **production** without taking
Smart Match offline.

> **The "Smart Match is temporarily unavailable" banner has TWO common causes.**
> `SmartMatch::ResultsController#show` wraps the whole results path in a
> catch-all `rescue => e` that renders this banner on **any** exception — so the
> message is misleading. **Always check the web logs for the real error**
> (`docker logs <web> | grep ResultsController`). The two usual culprits:
>
> 1. **Unrun migrations.** `kamal deploy` does **NOT** run `db:migrate`. A new
>    migration that isn't applied (e.g. a missing column) raises `PG::UndefinedColumn`,
>    which the catch-all turns into this banner. See [Database migrations](#database-migrations-kamal-does-not-run-them).
> 2. **Embedding accessory offline.** `kamal deploy` deploys the **app roles only**
>    (`web`, `worker`, `clock`) and does **NOT** touch **accessories**. If the
>    embedding accessory is missing/unhealthy/under-memory, the banner appears and
>    a normal `kamal deploy` will not fix it. See [The embedding accessory](#the-embedding-accessory-the-service-unavailable-cause).
>
> > **Smart Match is temporarily unavailable**
> > Our matching engine is currently offline. Please try again in a few minutes.

---

## Architecture (what runs where)

A single droplet per destination runs everything, all on the Docker network
named `kamal`:

| Container | Role | Source of truth |
|---|---|---|
| `giving-connection-web-<dest>-<sha>` | Rails web (`/up` healthcheck) | app image |
| `giving-connection-worker-<dest>-<sha>` | Sidekiq | app image |
| `giving-connection-clock-<dest>-<sha>` | Clockwork | app image |
| `giving-connection-embedding-api` | **Python BGE embedding service (accessory)** | `ghcr.io/teloslabs/gc-embedding-api` |

- The web/worker/clock containers reach the embedding service **by container
  name** over the `kamal` network:
  `EMBEDDING_SERVICE_URL=http://giving-connection-embedding-api:8000`
  (set in `config/deploy.yml` → `env.clear`).
- The accessory binds to `127.0.0.1:8000` on the host — **not** public.
- Embedding service source lives in this repo under `embedding-service/`.
  The deployed image (`gc-embedding-api`) is built/pushed from there separately
  (it is **not** built by `kamal deploy`).

Config files:
- `config/deploy.yml` — shared base (service name, registry, shared env/secrets).
- `config/deploy.staging.yml` — staging hosts + the `embedding-api` accessory.
- `config/deploy.production.yml` — production hosts + accessory.
- `.kamal/secrets-common`, `.kamal/secrets.staging`, `.kamal/secrets-production`
  — **gitignored, per-developer.** Kamal sources these for secrets.

---

## Prerequisites

- **Kamal 2.x** installed (standalone gem, *not* in the bundle):
  `kamal version` → `2.11.0` (or later).
- **Docker + buildx** running locally. `kamal deploy` cross-builds the app image
  for `amd64` on your machine, then pushes to ghcr.io.
- **SSH access** as `deploy@<host>` to the droplet (key-based).
- **Secrets present** in `.kamal/` (they are gitignored — get them from a
  teammate / vault if missing). Required keys in `.kamal/secrets-common`:
  `KAMAL_REGISTRY_USERNAME`, `KAMAL_REGISTRY_PASSWORD`, `RAILS_MASTER_KEY`,
  `DATABASE_URL`, `REDIS_URL`.

### Pre-flight checks (run before every deploy)

```bash
cd /path/to/giving-connection

# 1. Working tree clean and changes committed (Kamal builds from a git clone of HEAD,
#    so UNCOMMITTED changes are NOT deployed).
git status --porcelain

# 2. RAILS_MASTER_KEY in secrets must match config/master.key.
#    Drift here has broken staging healthchecks before (key rotation desync).
MK=$(grep '^RAILS_MASTER_KEY=' .kamal/secrets-common | cut -d= -f2)
[ "$MK" = "$(cat config/master.key)" ] && echo "master key OK" || echo "DRIFT — fix before deploying"

# 3. Tooling
kamal version
docker buildx version
```

---

## Database migrations (Kamal does NOT run them)

There is **no** auto-migration in this setup — no `bin/docker-entrypoint` running
`db:prepare`, and no Kamal migrate hook. `kamal deploy` ships the new code but
leaves the schema untouched. **If your deploy includes a migration, you must run
it yourself**, or Smart Match (and anything else touching the new schema) breaks
with `PG::UndefinedColumn` → the "temporarily unavailable" banner.

```bash
# Check what's pending on the deployed app (run AFTER the app deploy so the
# container has the new migration files):
kamal app exec --reuse -d staging "bin/rails db:migrate:status" | grep down

# Apply migrations:
kamal app exec --reuse -d staging "bin/rails db:migrate"
```

> Migrations here are additive (new nullable column + index, FK→cascade, vector
> dim constraint). Review any migration for destructive/locking operations before
> running against production. `db:migrate` is idempotent — safe to run when
> nothing is pending.

If a migration adds a column the new code reads (as `locations.state_code` does),
there's a window between the app swing and the migrate where requests error. For
a low-traffic staging this is fine; for production, run the migrate immediately
after deploy (or adopt the auto-migrate hook — see [Preventing recurrence](#preventing-recurrence)).

### Smart Match data backfills

Some Smart Match features need data populated after their migration:

```bash
# Populate locations.state_code from address (idempotent; only fills NULLs).
# SimilarityQuery falls back to ILIKE for NULLs, so this is accuracy, not crash-fix.
kamal app exec --reuse -d staging "bin/rails smart_match:backfill_location_state_codes"

# Organization embeddings must exist for matching to return anything:
kamal app exec --reuse -d staging "bin/rails runner 'puts OrganizationEmbedding.count'"
# 0 → run the embed job/backfill (see docs/smart-match-engine.md).
```

## The embedding accessory (the "service unavailable" cause)

The accessory is the #1 cause of Smart Match outages because **`kamal deploy`
ignores accessories entirely.** Two specific failure modes have happened:

1. **Never booted.** A fresh droplet (or one where the accessory was removed) has
   no `giving-connection-embedding-api` container. `kamal deploy` won't create it.
2. **Stale / under-memory config.** The committed config gives the accessory
   `memory: 2.5g` and a Docker healthcheck *specifically because* the BGE model
   OOMs at startup under a 1 GiB cap. If the running container was booted from an
   older config (e.g. `memory: 1g`, no healthcheck), it runs fragile/at-risk and
   OOMs on the next restart — but a `kamal deploy` will never re-apply the new
   limit, because it doesn't touch accessories.

> ⚠️ The droplet is **memory-tight** (~3.8 GiB total, **0 swap**). The 2.5g value
> is a *cap*, not a reservation — the model actually uses ~0.8 GiB at rest — so
> applying the cap is safe. But do **not** add more roles/accessories without
> checking `free -h` headroom first.

### Verify the accessory state (read-only)

```bash
HOST=138.197.90.4   # from config/deploy.staging.yml; production differs

ssh deploy@$HOST '
  echo "=== status / health ===";
  docker inspect --format "{{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}" giving-connection-embedding-api;
  echo "=== memory cap (bytes; 2684354560 == 2.5g, 1073741824 == 1g) ===";
  docker inspect --format "{{.HostConfig.Memory}}" giving-connection-embedding-api;
  echo "=== /health ===";
  curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/health
'
```

**Healthy target:** `running health=healthy`, memory cap `2684354560`, `/health → 200`.

- `health=none` → booted from a config without the healthcheck (stale). Reboot.
- memory cap `1073741824` (1g) → stale/fragile config. Reboot.
- container missing or `/health` ≠ 200 → boot it.

### Boot / reboot the accessory onto the committed config

```bash
# First boot (container does not exist):
kamal accessory boot embedding-api -d staging

# Re-apply committed config (memory cap, healthcheck) to an existing/stale container:
kamal accessory reboot embedding-api -d staging
```

`reboot` does **stop → remove → pull `:latest` → run** with the current config.
There is no memory overlap (old container is freed before the new one starts), so
it's memory-safe, but there is a **~90s embedding downtime** while the model loads
(`health-start-period: 90s`). Plan reboots accordingly.

> **Rollback anchor:** before a reboot, capture the running image digest so you can
> pin it back if `:latest` has drifted:
> ```bash
> ssh deploy@$HOST 'docker inspect --format "{{index .RepoDigests 0}}" \
>   $(docker inspect --format "{{.Image}}" giving-connection-embedding-api)'
> ```

### Wait until healthy (before deploying the app)

```bash
ssh deploy@$HOST '
  for i in $(seq 1 18); do
    H=$(docker inspect --format "{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}" giving-connection-embedding-api)
    C=$(curl -s -m 3 -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/health)
    echo "health=$H /health=$C"
    [ "$H" = "healthy" ] && [ "$C" = "200" ] && { echo HEALTHY; break; }
    sleep 10
  done
'
```

---

## Full deploy procedure

### Staging

```bash
cd /path/to/giving-connection

# 1. Pre-flight checks (above): clean tree, master key match, tooling.

# 2. Ensure the embedding accessory is healthy on the COMMITTED config.
#    Verify state; reboot/boot only if drifted or unhealthy, then wait for healthy.
kamal accessory reboot embedding-api -d staging   # if drift detected
#   ...wait-until-healthy loop...

# 3. Deploy the app roles (builds amd64 locally, pushes, rolls web/worker/clock
#    with healthchecks; ~7–8 min). Long-running — don't interrupt it.
kamal deploy -d staging

# 4. Run migrations (Kamal does NOT). Skips cleanly if nothing is pending.
kamal app exec --reuse -d staging "bin/rails db:migrate:status" | grep down   # see pending
kamal app exec --reuse -d staging "bin/rails db:migrate"
#    ...and any required backfill, e.g.:
kamal app exec --reuse -d staging "bin/rails smart_match:backfill_location_state_codes"

# 5. Verify end-to-end (next section).
```

### Production

Same steps with `-d production` and the production host from
`config/deploy.production.yml`. **Smoke-test on staging first.** Production has the
same accessory caveat — check it before/after.

```bash
kamal accessory reboot embedding-api -d production   # only if drift detected
kamal deploy -d production
kamal app exec --reuse -d production "bin/rails db:migrate"   # run migrations — Kamal won't
```

---

## Post-deploy verification (must pass)

This is the proof that Smart Match will not show "temporarily unavailable". The
last check exercises the exact code path that raises
`SmartMatch::EmbeddingUnavailableError`.

```bash
HOST=138.197.90.4   # staging

ssh deploy@$HOST '
  WEB=$(docker ps --format "{{.Names}}" | grep "web-staging" | head -1)
  echo "=== app version (should be the new git SHA) ==="
  docker exec "$WEB" printenv KAMAL_VERSION
  echo "=== embedding accessory ==="
  docker ps --format "{{.Names}}\t{{.Status}}" | grep embedding-api   # want: Up ... (healthy)
  echo "=== web -> embedding over kamal network ==="
  docker exec "$WEB" bash -lc "curl -s -m 5 -o /dev/null -w \"%{http_code}\n\" http://giving-connection-embedding-api:8000/health"   # want 200
  echo "=== EmbeddingClient end-to-end (the unavailable path) ==="
  docker exec "$WEB" bash -lc "bin/rails runner \"v = SmartMatch::EmbeddingClient.call(text: \\\"food assistance for veterans\\\"); puts \\\"DIMS=#{Array(v).length}\\\"\"" | tail -1   # want DIMS=1024
'

# Public proxy
curl -s -m 10 -o /dev/null -w "GET /up -> %{http_code}\n" https://staging.givingconnection.org/up           # 200
curl -s -m 10 -o /dev/null -w "GET /smart_match -> %{http_code}\n" https://staging.givingconnection.org/smart_match  # 200
```

Pass criteria: app on the new SHA · `embedding-api` `(healthy)` · web→embedding
`200` · `DIMS=1024` (bge-large-en-v1.5) · public endpoints `200`.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| "Smart Match temporarily unavailable" — **check logs first** (catch-all `rescue` hides the real error) | `docker logs <web> 2>&1 \| grep ResultsController` to see the actual exception | fix per the actual error (rows below) |
| logs show `PG::UndefinedColumn` / `relation does not exist` | a migration wasn't run — `kamal deploy` does not migrate | `kamal app exec --reuse -d <dest> "bin/rails db:migrate"` |
| "Smart Match temporarily unavailable" with no app error in logs | accessory missing / unhealthy / OOM; `kamal deploy` never touches it | Verify accessory; `kamal accessory boot\|reboot embedding-api -d <dest>`; wait for healthy |
| accessory `health=none` and/or memory cap `1073741824` | running from stale config | `kamal accessory reboot embedding-api -d <dest>` to re-apply committed 2.5g + healthcheck |
| accessory boots then dies/restarts within ~90s | model OOM (under-memory cap or host out of RAM) | Confirm cap is `2.5g`; check `free -h` (0 swap — needs ~1 GiB headroom) |
| web→embedding curl fails by name but `127.0.0.1:8000` works | containers not on the same `kamal` network | `docker inspect --format '{{range $k,$_ := .NetworkSettings.Networks}}{{$k}} {{end}}' <container>`; reboot accessory so it rejoins `kamal` |
| Healthcheck fails right after deploy / app won't boot | `RAILS_MASTER_KEY` in `.kamal/secrets-common` ≠ `config/master.key` | Re-sync the key, redeploy |
| Deployed code missing my latest change | uncommitted work — Kamal builds from a git clone of HEAD | Commit, then `kamal deploy` |
| `kamal deploy` interrupted; lock stuck | killed mid-deploy | `kamal lock release -d <dest>`, then redeploy |

## Preventing recurrence

Two manual steps must not be forgotten on every deploy: **run migrations** and
**keep the embedding accessory healthy**. To stop relying on memory:

- **Auto-migrate on deploy.** Add a Kamal post-deploy hook
  (`.kamal/hooks/post-deploy`) that runs
  `kamal app exec --reuse -d "$KAMAL_DESTINATION" "bin/rails db:migrate"`, or add a
  `bin/docker-entrypoint` that runs `./bin/rails db:prepare` for the web role only.
  Trade-off: with the app swung before the migrate, additive migrations are fine but
  a column-rename style change needs the expand/contract pattern. Not yet wired up —
  decide before enabling on production.
- **Accessory healthcheck** is already in the committed config; keep it so Kamal/Docker
  surfaces an unhealthy model instead of silently serving errors.

## Notes

- Roll back the app: `kamal rollback -d <dest>` (or `kamal app boot --version <sha>`).
- The embedding image (`gc-embedding-api`) is **not** built by `kamal deploy`. If
  it needs rebuilding, build/push from `embedding-service/` first, then
  `kamal accessory reboot embedding-api -d <dest>`.
- Hosts and the public hostname come from `config/deploy.<dest>.yml` — treat the
  IPs in this doc as examples and confirm against the config before deploying.
