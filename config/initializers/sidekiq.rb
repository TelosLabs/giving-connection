REDIS_URL = if Rails.env.production?
  ENV["REDIS_URL"] || ENV["REDISCLOUD_URL"] || Rails.application.credentials.dig(:production, :redis_url)
elsif Rails.env.staging?
  ENV["REDIS_URL"] || ENV["REDISCLOUD_URL"] || Rails.application.credentials.dig(:staging, :redis_url)
else
  ENV["REDIS_URL"] || ENV["REDISCLOUD_URL"] || Rails.application.credentials.dig(:development, :redis_url) || "redis://localhost:6379/0"
end

REDIS_SSL_PARAMS = REDIS_URL&.start_with?("rediss://") ? {verify_mode: OpenSSL::SSL::VERIFY_NONE} : nil

redis_config = {url: REDIS_URL}
redis_config[:ssl_params] = REDIS_SSL_PARAMS if REDIS_SSL_PARAMS

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end
