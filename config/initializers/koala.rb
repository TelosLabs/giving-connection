# frozen_string_literal: true

# Be sure to restart your server when you modify this file.
Koala.configure do |config|
  config.access_token = Rails.application.credentials.dig(:instagram, :access_token)
  config.app_id = Rails.application.credentials.dig(:instagram, :app_id)
  config.app_secret = Rails.application.credentials.dig(:instagram, :app_secret)
  # See Koala::Configuration for more options, including details on how to send requests through
  # your own proxy servers.
end
