# frozen_string_literal: true

# Sessions are stored in Redis (DB index /2) for the WHOLE app, not just Smart
# Match. Rationale: the Smart Match quiz keeps ~10 steps of answers in the
# session, which exceeds the 4KB limit of the default encrypted cookie store, so
# it requires server-side session storage. Rails' session store is global (it
# can't be scoped to one controller), so the whole app moves to Redis sessions.
#
# This is acceptable because Redis is already a hard runtime dependency of this
# app: Sidekiq (the ActiveJob queue adapter, DB /0) and Action Cable (DB /1)
# both require it. Redis DBs in use: /0 Sidekiq, /1 Action Cable, /2 sessions.
#
# TRADE-OFF / OPS NOTE: putting sessions in Redis newly couples auth/login to
# Redis availability -- if Redis is down, no one can hold a session or log in
# (previously a Redis outage only degraded jobs/websockets). Redis MUST be up
# before the web process boots. On staging this means the Redis unit needs
# `After=docker.service`/`Requires=docker.service` or sessions silently break
# (symptom: the quiz appears stuck on the same step). See docs/deployment.md.
redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
session_redis_url = "#{redis_url.sub(%r{/\d+\z}, "")}/2"

redis_options = {url: session_redis_url}

if session_redis_url.start_with?("rediss://") && Rails.env.local?
  redis_options[:ssl_params] = {verify_mode: OpenSSL::SSL::VERIFY_NONE}
end

Rails.application.config.session_store :redis_session_store,
  key: "_giving_connection_session",
  expire_after: 1.day,
  secure: Rails.env.production? || Rails.env.staging?,
  httponly: true,
  same_site: :lax,
  redis: redis_options
