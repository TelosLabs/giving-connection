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
  Rack::Attack.cache.store = Redis.new(**rack_attack_redis_options)

  ### Client IP resolution ###

  # Behind kamal-proxy the app sees the proxy's private Docker IP in REMOTE_ADDR
  # and the real visitor in X-Forwarded-For. Rack's own `req.ip` uses a cruder
  # algorithm than Rails and can end up bucketing many visitors under a single
  # proxy IP — which makes a shared throttle fire during ordinary browsing.
  #
  # ActionDispatch::RemoteIp runs earlier in the middleware stack (before
  # Rack::Attack) and already resolves the true client while respecting trusted
  # proxies, so reuse its result. Fall back to `ip` if it isn't set (e.g. tests).
  class Request < ::Rack::Request
    def remote_ip
      @remote_ip ||= (env["action_dispatch.remote_ip"] || ip).to_s
    end
  end

  # Development-specific settings for easier testing
  THROTTLE_PERIODS = if Rails.env.development?
    {
      registration_ip: 5.minutes,      # Instead of 1 hour
      suspicious_domain: 5.minutes,    # Instead of 1 hour
      login: 20.seconds,               # Keep as is for login
      blog_anonymous: 5.minutes,
      feedback: 5.minutes
    }.freeze
  elsif Rails.env.test?
    {
      registration_ip: 1.second,      # Effectively disable throttling
      suspicious_domain: 1.second,    # Effectively disable throttling
      login: 1.second,                # Effectively disable throttling
      blog_anonymous: 1.second,
      feedback: 1.second
    }.freeze
  else
    {
      registration_ip: 1.hour,
      suspicious_domain: 1.hour,
      login: 20.seconds,
      blog_anonymous: 1.hour,
      feedback: 1.hour
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
  #
  # Exclude framework-served paths that a single page load fans out into —
  # bundled assets, ActiveStorage image variants (org logos/covers), Action
  # Cable, and the health check. Counting these made image-heavy pages (search
  # results, the map) exhaust the budget during normal navigation and trip the
  # throttle on legitimate users.
  EXCLUDED_FROM_REQ_THROTTLE = ["/assets", "/packs", "/rails/active_storage", "/cable", "/up"].freeze
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.remote_ip unless EXCLUDED_FROM_REQ_THROTTLE.any? { |prefix| req.path.start_with?(prefix) }
  end

  ### Prevent Registration Spam ###

  # Throttle new account registrations by IP.
  #
  # A limit of 1/hour blocked legitimate visitors who share an IP (offices,
  # campuses, carrier-grade NAT) — the second person to sign up from that IP was
  # rejected. 5/hour still stops automated bulk-registration while leaving room
  # for real shared-network signups.
  throttle("registrations/ip", limit: 5, period: THROTTLE_PERIODS[:registration_ip]) do |req|
    if req.path == "/users" && req.post?
      Rails.logger.info "[Rack::Attack] Registration attempt from IP: #{req.remote_ip}" if Rails.env.development?
      req.remote_ip
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

  # Return a custom error message for throttled requests.
  #
  # The message is chosen by the NAME of the throttle that matched
  # (`rack.attack.matched`), not by the discriminator value. The previous
  # version keyed off the discriminator and, because most throttles discriminate
  # on the client IP, it labelled every IP-based throttle — including the general
  # req/ip navigation throttle — as a "registration attempt", which is what made
  # ordinary page browsing surface a registration error.
  Rack::Attack.throttled_responder = lambda do |request|
    now = Time.now.utc
    match_data = request.env["rack.attack.match_data"]
    matched = request.env["rack.attack.matched"]

    Rails.logger.info "[Rack::Attack] Throttle triggered: #{matched}"
    Rails.logger.info "[Rack::Attack] Match data: #{match_data.inspect}"
    Rails.logger.info "[Rack::Attack] Request path: #{request.path}"
    Rails.logger.info "[Rack::Attack] Client IP: #{request.remote_ip}"

    period = match_data[:period]
    retry_after = period - (now.to_i % period)

    headers = {
      "Content-Type" => "application/json",
      "Retry-After" => retry_after.to_s
    }

    message = case matched
    when "registrations/ip"
      "Too many registration attempts from this IP address. Please try again in #{retry_after} seconds."
    when "registrations/suspicious_email_domain"
      "Registration attempts from this email domain are temporarily restricted. Please try again in #{retry_after} seconds or use a different email provider."
    when "logins/ip", "logins/email"
      "Too many login attempts. Please try again in #{retry_after} seconds."
    else
      "Too many requests. Please try again in #{retry_after} seconds."
    end

    [
      429,
      headers,
      [{
        error: message,
        retry_after: retry_after,
        throttle_type: matched
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
      req.remote_ip
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
        Rails.logger.info "[Rack::Attack] Anonymous blog creation from IP: #{req.remote_ip}" if Rails.env.development?
        req.remote_ip
      end
    end
  end

  ### Prevent Feedback Spam ###

  def self.feedback_discriminator(req)
    return unless req.path == "/feedbacks" && req.post?

    user = req.env["warden"]&.user(:user)
    discriminator = user ? "user:#{user.id}" : req.remote_ip

    Rails.logger.info "[Rack::Attack] Feedback submission from: #{discriminator}" if Rails.env.development?
    discriminator
  end

  throttle("feedbacks", limit: 10, period: THROTTLE_PERIODS[:feedback]) do |req|
    Rack::Attack.feedback_discriminator(req)
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

  # Safelist health check endpoint from throttling
  safelist("health-check") do |req|
    req.path == "/up"
  end

  # Clean up expired keys periodically (runs async in Redis)
  # Skip during Docker builds (e.g., assets:precompile) where Redis isn't available
  unless ENV["SECRET_KEY_BASE"] == "placeholder_for_build"
    if defined?(Rails.cache) && Rails.cache.respond_to?(:redis)
      Rails.cache.redis.with do |redis|
        redis.expire(CACHE_PREFIX, 24.hours.to_i)
      end
    end
  end
end
