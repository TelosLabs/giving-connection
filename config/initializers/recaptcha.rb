Recaptcha.configure do |config|
  config.site_key = Rails.application.credentials.dig(:recaptcha, :RECAPTCHA_SITE_KEY)
  config.secret_key = Rails.application.credentials.dig(:recaptcha, :RECAPTCHA_SECRET_KEY)
  config.skip_verify_env = ['development']
end
