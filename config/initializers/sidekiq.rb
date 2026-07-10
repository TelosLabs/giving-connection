REDIS_URL = if Rails.env.production?
  ENV["REDIS_URL"] || ENV["REDISCLOUD_URL"] || Rails.application.credentials.dig(:production, :redis_url)
elsif Rails.env.staging?
  ENV["REDIS_URL"] || ENV["REDISCLOUD_URL"] || Rails.application.credentials.dig(:staging, :redis_url)
else
  ENV["REDIS_URL"] || ENV["REDISCLOUD_URL"] || Rails.application.credentials.dig(:development, :redis_url) || "redis://localhost:6379/0"
end

sidekiq_redis_config = lambda {
  config = {url: REDIS_URL}
  config
}

Sidekiq.configure_server do |config|
  config.redis = sidekiq_redis_config.call
end

Sidekiq.configure_client do |config|
  config.redis = sidekiq_redis_config.call
end
