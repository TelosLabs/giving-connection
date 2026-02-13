require "rack/attack"

class Rack::Attack
  ### Configure Cache ###

  CACHE_PREFIX = "rack::attack".freeze

  # Use Redis as our cache backend
  rack_attack_redis_url = ENV["REDIS_URL"] || ENV["REDISCLOUD_URL"] || "redis://localhost:6379/1"
  rack_attack_redis_options = {
    url: rack_attack_redis_url,
    reconnect_attempts: 1,
    timeout: 1
  }
  rack_attack_redis_options[:ssl_params] = {verify_mode: OpenSSL::SSL::VERIFY_NONE} if rack_attack_redis_url.start_with?("rediss://")
  Rack::Attack.cache.store = Redis.new(**rack_attack_redis_options)

  # Development-specific settings for easier testing
  THROTTLE_PERIODS = if Rails.env.development?
    {
      registration_ip: 5.minutes,      # Instead of 1 hour
      suspicious_domain: 5.minutes,    # Instead of 1 hour
      login: 20.seconds,               # Keep as is for login
      blog_anonymous: 5.minutes
    }.freeze
  elsif Rails.env.test?
    {
      registration_ip: 1.second,      # Effectively disable throttling
      suspicious_domain: 1.second,    # Effectively disable throttling
      login: 1.second,                # Effectively disable throttling
      blog_anonymous: 1.second
    }.freeze
  else
    {
      registration_ip: 1.hour,
      suspicious_domain: 1.hour,
      login: 20.seconds,
      blog_anonymous: 1.hour
    }.freeze
  end

  ### Throttle Spammy Clients ###

  # If any single client IP is making tons of requests, then they're
  # probably malicious or a poorly-configured scraper. Either way, they
  # don't deserve to hog all of the app server's CPU. Cut them off!
  #
  # Note: If you're serving assets through rack, those requests may be
  # counted by rack-attack and this throttle may be activated too
  # quickly. If so, enable the condition to exclude them from tracking.

  # Throttle all requests by IP (60rpm)
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  ### Prevent Registration Spam ###

  # Throttle new account registrations by IP
  throttle("registrations/ip", limit: 1, period: THROTTLE_PERIODS[:registration_ip]) do |req|
    if req.path == "/users" && req.post?
      Rails.logger.info "[Rack::Attack] Registration attempt from IP: #{req.ip}" if Rails.env.development?
      req.ip
    end
  end

  # Allow list of common email providers that shouldn't be restricted
  ALLOWED_EMAIL_PROVIDERS = %w[
    gmail.com
    outlook.com
    hotmail.com
    yahoo.com
    icloud.com
    aol.com
    protonmail.com
    proton.me
    me.com
    msn.com
    live.com
    mail.com
  ].freeze

  # Stricter throttling for suspicious email domains
  throttle("registrations/suspicious_email_domain", limit: 2, period: THROTTLE_PERIODS[:suspicious_domain]) do |req|
    if req.path == "/users" && req.post? && req.params["user"].present?
      email = req.params["user"]["email"].to_s
      domain = email.split("@").last.to_s.downcase if email.include?("@")

      if Rails.env.development?
        Rails.logger.info "[Rack::Attack] Registration email domain: #{domain}"
        Rails.logger.info "[Rack::Attack] Is suspicious domain? #{!ALLOWED_EMAIL_PROVIDERS.include?(domain)}"
      end

      if domain.present? && !ALLOWED_EMAIL_PROVIDERS.include?(domain)
        domain
      end
    end
  end

  # Return a custom error message for throttled registration attempts
  Rack::Attack.throttled_responder = lambda do |request|
    now = Time.now.utc
    match_data = request.env["rack.attack.match_data"]

    Rails.logger.info "[Rack::Attack] Throttle triggered"
    Rails.logger.info "[Rack::Attack] Match data: #{match_data.inspect}"
    Rails.logger.info "[Rack::Attack] Request path: #{request.path}"
    Rails.logger.info "[Rack::Attack] Client IP: #{request.ip}"

    period = match_data[:period]
    retry_after = period - (now.to_i % period)

    # Determine the type of throttle that was triggered
    throttle_type = case match_data[:discriminator]
    when request.ip
      "IP-based rate limit"
    when ->(d) { d.is_a?(String) && d.include?(".") }
      "Suspicious email domain"
    else
      "Rate limit"
    end

    headers = {
      "Content-Type" => "application/json",
      "Retry-After" => retry_after.to_s
    }

    message = case throttle_type
    when "IP-based rate limit"
      "Too many registration attempts from this IP address. Please try again in #{retry_after} seconds."
    when "Suspicious email domain"
      "Registration attempts from this email domain are temporarily restricted. Please try again in #{retry_after} seconds or use a different email provider."
    else
      "Too many attempts. Please try again in #{retry_after} seconds."
    end

    [
      429,
      headers,
      [{
        error: message,
        retry_after: retry_after,
        throttle_type: throttle_type
      }.to_json]
    ]
  end

  ### Prevent Brute-Force Login Attacks ###

  # The most common brute-force login attack is a brute-force password
  # attack where an attacker simply tries a large number of emails and
  # passwords to see if any credentials match.
  #
  # Another common method of attack is to use a swarm of computers with
  # different IPs to try brute-forcing a password for a specific account.

  # Throttle POST requests to /login by IP address
  throttle("logins/ip", limit: 5, period: THROTTLE_PERIODS[:login]) do |req|
    if req.path == "/login" && req.post?
      req.ip
    end
  end

  # Throttle POST requests to /login by email param
  throttle("logins/email", limit: 5, period: THROTTLE_PERIODS[:login]) do |req|
    if req.path == "/login" && req.post?
      req.params["email"].to_s.downcase.gsub(/\s+/, "").presence
    end
  end

  ### Prevent Blog Spam ###
  # Stricter throttle for anonymous users (no session/auth)
  throttle("blogs/anonymous", limit: 3, period: THROTTLE_PERIODS[:blog_anonymous]) do |req|
    if req.path == "/blogs" && req.post?
      # Check if user is authenticated by looking for Devise session
      is_authenticated = req.env["warden"]&.authenticated?

      unless is_authenticated
        Rails.logger.info "[Rack::Attack] Anonymous blog creation from IP: #{req.ip}" if Rails.env.development?
        req.ip
      end
    end
  end

  ### Custom Throttle Response ###

  # By default, Rack::Attack returns an HTTP 429 for throttled responses,
  # which is just fine.
  #
  # If you want to return 503 so that the attacker might be fooled into
  # believing that they've successfully broken your app (or you just want to
  # customize the response), then uncomment these lines.
  # self.throttled_responder = lambda do |env|
  #  [ 503,  # status
  #    {},   # headers
  #    ['']] # body
  # end

  # Clean up expired keys periodically (runs async in Redis)
  # Skip during rake tasks (e.g., assets:precompile) where Redis isn't available
  unless defined?(Rake)
    if defined?(Rails.cache) && Rails.cache.respond_to?(:redis)
      Rails.cache.redis.with do |redis|
        redis.expire(CACHE_PREFIX, 24.hours.to_i)
      end
    end
  end
end
