Recaptcha.configure do |config|
  config.site_key = Rails.application.credentials.dig(:recaptcha, :RECAPTCHA_SITE_KEY) || "test-site-key"
  config.secret_key = Rails.application.credentials.dig(:recaptcha, :RECAPTCHA_SECRET_KEY) || "test-secret-key"
  config.skip_verify_env = %w[development test]
end
