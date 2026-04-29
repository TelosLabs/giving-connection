# Heroku to DigitalOcean Migration Plan

## Overview

Migrate Giving Connection from Heroku to DigitalOcean using Kamal for container orchestration. Both **staging** and **production** environments will be migrated, each to its own droplet. Kamal destinations handle this: `kamal deploy -d staging` and `kamal deploy -d production`.

**Migration order:** Staging first, validate thoroughly, then production.

**Cost estimate:** ~$102/mo total (staging $24 + production $78) vs ~$285-300/mo on Heroku.

---

## Phase 1 — Can Be Done Now (Before Maintenance Window)

These steps carry zero risk to the live Heroku apps.

### 1.1 Infrastructure Provisioning

**Staging — self-hosted (single droplet, ~$24/mo):**

Postgres and Redis run on the staging droplet itself. This keeps staging cheap
and simple. The tradeoff is no managed backups — use manual `pg_dump` if needed.

- [x] Provision DO droplet for staging (2 vCPU / 4GB RAM, Ubuntu 24.04)
- [ ] Configure DO Cloud Firewall for staging droplet (see Security section)
- [ ] Create `deploy` user on staging droplet with SSH key access
- [ ] Install Docker on staging droplet
- [ ] Install and configure PostgreSQL with PostGIS + pgvector on staging droplet
- [ ] Install and configure Redis on staging droplet (bind to 127.0.0.1)

**Production — managed services (~$78/mo):**

Postgres and Redis are DO Managed services with automated backups,
trusted source access control, and patching handled by DO.

- [x] Provision DO droplet for production (4 vCPU / 8GB RAM, Ubuntu 24.04)
- [x] Provision DO Managed PostgreSQL for production (enable PostGIS, pgvector) (~$15/mo)
- [x] Provision DO Managed Redis for production (self-hosted)
- [x] Configure DO Cloud Firewall for production droplet (see Security section)
- [ ] Create `deploy` user on production droplet with SSH key access
- [x] Install Docker on production droplet
- [x] Configure Managed Postgres trusted sources → production droplet private IP only
- [ ] Disable public access on both managed databases

**Shared:**
- [ ] Set up GHCR access (GitHub PAT with `packages:read` and `packages:write`)
- [ ] Create `.kamal/secrets` file locally (gitignored) with staging values first

### 1.2 DNS Preparation

- [ ] Lower DNS TTL to 60 seconds for staging domain (at least 48h before cutover)
- [ ] Lower DNS TTL to 60 seconds for production domain (at least 48h before cutover)
- [ ] Document current DNS records for both environments (for rollback)
- [ ] Prepare new A records pointing to DO droplet IPs (do not apply yet)

### 1.3 Secrets Setup

Each destination needs its own `.kamal/secrets` file or destination-specific env.
Generate **new** credentials — do NOT reuse Heroku values.

**Per-environment secrets:**

| Variable | Staging | Production | Notes |
|---|---|---|---|
| `RAILS_MASTER_KEY` | Same key (shares credentials.yml.enc) | Same key | Only rotate if you re-encrypt credentials |
| `DATABASE_URL` | DO staging Postgres URL | DO production Postgres URL | App does `.sub(/^postgres/, "postgis")` automatically |
| `REDIS_URL` | DO staging Redis URL | DO production Redis URL | Use `redis://` for DO Managed Redis |
| `KAMAL_REGISTRY_USERNAME` | GitHub username | GitHub username | Same for both |
| `KAMAL_REGISTRY_PASSWORD` | GitHub PAT | GitHub PAT | Same for both |

### 1.4 Build and Push Docker Image

```bash
# Build the production image locally and push to GHCR
docker build -t ghcr.io/teloslabs/giving-connection:latest .
docker push ghcr.io/teloslabs/giving-connection:latest

# Build the embedding service image
docker build -t ghcr.io/teloslabs/gc-embedding-api:latest ./embedding-service
docker push ghcr.io/teloslabs/gc-embedding-api:latest
```

### 1.5 Staging Database — Self-Hosted Setup & Restore

**Install Postgres with PostGIS on the staging droplet:**

```bash
# SSH into staging droplet
ssh deploy@STAGING_IP

# Install PostgreSQL 16 + PostGIS
sudo apt update
sudo apt install -y postgresql-16 postgresql-16-postgis-3 postgresql-16-pgvector

# Create the database and enable extensions
sudo -u postgres psql <<EOF
CREATE USER giving_connection WITH PASSWORD 'STAGING_DB_PASSWORD';
CREATE DATABASE giving_connection_staging OWNER giving_connection;
\c giving_connection_staging
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
CREATE EXTENSION IF NOT EXISTS vector;
EOF
```

The staging `DATABASE_URL` will be: `postgres://giving_connection:STAGING_DB_PASSWORD@127.0.0.1:5432/giving_connection_staging`
****
**Install Redis on the staging droplet:**
****
```bash
sudo apt install -y redis-server

# Bind to localhost only (edit /etc/redis/redis.conf)
sudo sed -i 's/^bind .*/bind 127.0.0.1 ::1/' /etc/redis/redis.conf
sudo systemctl restart redis-server
```

**The** staging `REDIS_URL` will be: `redis://127.0.0.1:6379`

**Restore staging data from Heroku:******

Staging can be restored from a Heroku backup at any time. This data will go stale,
but it validates the restore process before production cutover.

```bash
# Capture Heroku staging backup
heroku pg:backups:capture -a giving-connection-staging

# Download it
heroku pg:backups:url -a giving-connection-staging
curl -o staging_backup.dump "<BACKUP_URL>"

# Restore to self-hosted staging Postgres
pg_restore --no-owner --no-acl --verbose \
  --dbname="postgres://giving_connection:STAGING_DB_PASSWORD@STAGING_IP:5432/giving_connection_staging" \
  staging_backup.dump
```

Verify (see Post-Restore Verification below).

### 1.6 Deploy to Staging

```bash
# First-time setup (installs Docker, kamal-proxy, etc.)
kamal setup -d staging

# Subsequent deploys
kamal deploy -d staging
```

### 1.7 Validate Staging

```bash
# Check containers
kamal details -d staging

# Health check
curl -s https://STAGING_DOMAIN/up

# Logs
kamal logs -f -d staging
kamal logs -f -d staging --role worker
kamal logs -f -d staging --role clock

# Embedding service (from droplet)
ssh deploy@STAGING_IP 'curl -s http://127.0.0.1:8000/health'
```

Run the full smoke test checklist (see Monitoring Continuity section below).

**Staging must be fully validated before proceeding to production.**

---

## Phase 2 — Production Cutover (Maintenance Window)

Schedule for **2-4 AM ET** to minimize user impact.

### 2.1 Pre-Cutover Checklist

- [ ] Staging is running and fully validated on DO
- [ ] DNS TTLs were lowered at least 48 hours ago
- [ ] `.kamal/secrets` has production values configured
- [ ] Team members are available for the cutover window
- [ ] Rollback plan is understood by all participants

### 2.2 Production Database Migration

```bash
# 1. Put Heroku production in maintenance mode
heroku maintenance:on -a giving-connection

# 2. Wait for in-flight requests to complete (~30 seconds)

# 3. Capture final production backup
heroku pg:backups:capture -a giving-connection
heroku pg:backups:url -a giving-connection
curl -o production_backup.dump "<BACKUP_URL>"

# 4. Prepare DO production Postgres (if not already done)
psql "<DO_PRODUCTION_DATABASE_URL>" <<EOF
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
CREATE EXTENSION IF NOT EXISTS vector;
EOF

# 5. Restore to DO production
pg_restore --no-owner --no-acl --verbose \
  --dbname="<DO_PRODUCTION_DATABASE_URL>" production_backup.dump
```

### 2.3 Post-Restore Verification

```bash
psql "<DO_PRODUCTION_DATABASE_URL>" <<EOF
-- Verify PostGIS
SELECT PostGIS_Version();

-- Verify pgvector
SELECT extversion FROM pg_extension WHERE extname = 'vector';

-- Verify table counts (compare with Heroku)
SELECT schemaname, relname, n_live_tup
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC
LIMIT 20;

-- Verify organizations (critical table)
SELECT COUNT(*) FROM organizations;

-- Verify locations with geography data
SELECT COUNT(*) FROM locations WHERE lonlat IS NOT NULL;

-- Verify users
SELECT COUNT(*) FROM users;

-- Verify indexes are present
SELECT indexname FROM pg_indexes WHERE schemaname = 'public' ORDER BY indexname;
EOF
```

Compare ALL counts against Heroku. Any discrepancy must be investigated before proceeding.

### 2.4 Deploy to Production

```bash
# First-time setup
kamal setup -d production

# Verify health
curl -s https://PRODUCTION_DOMAIN/up
```

### 2.5 DNS Cutover

1. Update DNS A record to point to production DO droplet IP
2. Wait for propagation (should be fast with 60s TTL)
3. Verify: `curl -I https://PRODUCTION_DOMAIN`
4. Verify: site loads correctly in browser, test login, test search

### 2.6 Post-Cutover Monitoring

- [ ] Watch Rollbar for new errors (first 30 minutes actively)
- [ ] Watch Scout APM for response time anomalies
- [ ] Monitor droplet CPU/memory via DO dashboard
- [ ] Check Sidekiq dashboard at /sidekiq
- [ ] Verify Clockwork fires the 08:00 ET alert job next morning
- [ ] Run full smoke test checklist (see below)

### 2.7 Finalize

- [ ] If stable after 24 hours, restore DNS TTL to normal (3600s)
- [ ] If stable after 1 week, decommission Heroku apps
- [ ] Keep Heroku backups archived for 30 days after decommission

---

## Rollback Plan

### Staging Rollback

Staging rollback is low-stakes — just point DNS back to Heroku staging or take down the DO staging instance. No data loss concerns.

### Production Rollback

If critical issues are discovered after production cutover:

1. Update DNS A record back to Heroku's DNS target
2. Turn off Heroku maintenance mode: `heroku maintenance:off -a giving-connection`
3. Data written to DO database during the cutover window will be lost — assess impact
4. Investigate and fix the issue on DO
5. Re-attempt cutover in next maintenance window

**Key:** Keep the cutover window short. Heroku maintenance mode blocks writes, so no data divergence occurs between the dump and DNS switch. The risk window is only after DNS points to DO.

---

## Security & Infrastructure Hardening

### DigitalOcean Cloud Firewall

Apply the same firewall rules to **both** staging and production droplets:

**Inbound:**

| Port | Protocol | Source | Purpose |
|---|---|---|---|
| 22 | TCP | Team IPs only | SSH access |
| 80 | TCP | All | HTTP (redirects to HTTPS via Kamal proxy) |
| 443 | TCP | All | HTTPS |

**All other inbound traffic must be denied.** Specifically:
- Port 3000 (Puma) — NOT exposed; Kamal proxy handles routing
- Port 5432 (Postgres) — NOT exposed; accessed via DO private network
- Port 6379 (Redis) — NOT exposed; accessed via DO private network or localhost
- Port 8000 (embedding API) — NOT exposed; bound to 127.0.0.1 only

**Outbound:** Allow all (needed for S3, SMTP, external APIs).

### Database Access Control

**Staging (self-hosted on droplet):**
- PostgreSQL listens on 127.0.0.1 only (default pg_hba.conf)
- Port 5432 is NOT exposed in the **firewall**
- Use a strong password for the `giving_connection` database user

**Production (DO Managed Postgres):**
- "Trusted Sources": restrict to the production droplet's private IP only
- Disable "Allow connections from the public internet"
- Use a strong, unique generated password (not reused from Heroku)

### Redis Access Control

**Staging (self-hosted on droplet):**
- Bind to 127.0.0.1 only in redis.conf
- Port 6379 is NOT exposed in the firewall
- Optionally set a requirepass password

**Production (DO Managed Redis):**
- Restrict trusted sources to the production droplet's private IP
- Enable TLS if desired (app code handles both `redis://` and `rediss://`)

### SSH Access

- Key-only authentication on both droplets (disable PasswordAuthentication)
- Use `deploy` user for Kamal (no root SSH login)
- Document which team members have SSH access and their public keys
- Use DO VPC for private networking between droplets and managed services

### Secrets Management

- All secrets in `.kamal/secrets` (gitignored, never committed)
- Separate secrets per destination (staging vs production DATABASE_URL, REDIS_URL)
- Rotate these credentials during migration — do NOT reuse Heroku values:
  - Database password
  - Redis password
  - RAILS_MASTER_KEY (optional — requires re-encrypting credentials.yml.enc)
- Never pass secrets as Docker build args or in env.clear

### Container Image Security

- Both environments share the same Docker image (same GHCR tag or version tags)
- Recommend adding a scan step in CI before pushing to GHCR:
  ```bash
  docker scout cves giving-connection:latest
  # or
  trivy image giving-connection:latest
  ```
- Production images use non-root user (`rails` uid 1000)
- Multi-stage build ensures no build tools or -dev packages in runtime image

### SSL/TLS

- Kamal proxy handles Let's Encrypt provisioning automatically per destination
- Each domain (staging + production) gets its own certificate
- Certificates renew automatically before expiry
- Ensure port 80 remains open on both droplets (Let's Encrypt HTTP-01 challenge)
- Monitor for "certificate" errors in Kamal proxy logs

### Monitoring Continuity

Post-migration smoke test checklist (**run for each environment**):

- [ ] Rollbar: trigger test error (`Rollbar.error("Migration smoke test")` in console)
- [ ] Scout APM: load pages, verify traces appear
- [ ] Sidekiq: enqueue a test job, verify processing at /sidekiq
- [ ] Action Cable: test WebSocket connection if used
- [ ] Mailer: trigger a test email, verify Mailchimp SMTP delivery
- [ ] Active Storage: upload a test image, verify it reaches S3
- [ ] Geocoder: test a location search, verify Google Geocoder API responds

### Backup Strategy

**Staging (self-hosted):**
- No automated backups — staging data is expendable and can be re-restored from Heroku
- Manual backups before risky operations:
  ```bash
  ssh deploy@STAGING_IP "sudo -u postgres pg_dump -Fc giving_connection_staging" > staging_backup_$(date +%Y%m%d).dump
  ```

**Production (DO Managed Postgres):**
- Enable automated daily backups (DO provides this by default)
- Retention: 7 days minimum
- Before risky operations: take manual backup via DO dashboard

**Manual production backup:**
```bash
pg_dump --no-owner --no-acl --format=custom \
  --verbose "<DO_PRODUCTION_DATABASE_URL>" > backup_$(date +%Y%m%d_%H%M%S).dump
```

Store production backups in a dedicated S3 bucket or DO Spaces.

---

## Complete Environment Variable Reference

**Per-destination values** (different for staging vs production):

| Variable | Example (staging) | Example (production) |
|---|---|---|
| `RAILS_MASTER_KEY` | `abc123...` | `abc123...` (same unless rotated) |
| `DATABASE_URL` | `postgres://user:pass@staging-db:25060/gc_staging?sslmode=require` | `postgres://user:pass@prod-db:25060/gc_prod?sslmode=require` |
| `REDIS_URL` | `redis://default:pass@staging-redis:25061` | `redis://default:pass@prod-redis:25061` |

**Shared values** (set in deploy.yml env.clear, same for both):

| Variable | Value | Notes |
|---|---|---|
| `RAILS_LOG_TO_STDOUT` | `1` | Always on |
| `RAILS_SERVE_STATIC_FILES` | `1` | Kamal proxy serves, but Puma handles static as fallback |
| `RUBY_YJIT_ENABLE` | `1` | Performance optimization |

**Per-destination values** (set in destination yml files):

| Variable | Staging | Production | Notes |
|---|---|---|---|
| `RAILS_ENV` | `staging` | `production` | Set in deploy.staging.yml / deploy.production.yml |
| `WEB_CONCURRENCY` | `1` | `2` | Puma workers, adjust for droplet RAM |

**Registry credentials** (same for both, in `.kamal/secrets`):

| Variable | Notes |
|---|---|
| `KAMAL_REGISTRY_USERNAME` | GitHub username |
| `KAMAL_REGISTRY_PASSWORD` | GitHub PAT with packages scope |
