REDIS_URL = if Rails.env.production?
  ENV["REDIS_URL"] || Rails.application.credentials.production[:redis_url]
elsif Rails.env.staging?
  ENV["REDIS_URL"] || Rails.application.credentials.staging[:redis_url]
else
  ENV["REDISCLOUD_URL"] || Rails.application.credentials.development[:redis_url]
end

Sidekiq.configure_server do |config|
  config.redis = {
    url: REDIS_URL,
    ssl_params: {verify_mode: OpenSSL::SSL::VERIFY_NONE}
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: REDIS_URL,
    ssl_params: {verify_mode: OpenSSL::SSL::VERIFY_NONE}
  }
end
