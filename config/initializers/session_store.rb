# frozen_string_literal: true

redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
session_redis_url = "#{redis_url.sub(%r{/\d+\z}, "")}/2"

redis_options = {url: session_redis_url}

if session_redis_url.start_with?("rediss://")
  redis_options[:ssl_params] = {verify_mode: OpenSSL::SSL::VERIFY_NONE}
end

Rails.application.config.session_store :redis_session_store,
  key: "_giving_connection_session",
  expire_after: 1.day,
  redis: redis_options
