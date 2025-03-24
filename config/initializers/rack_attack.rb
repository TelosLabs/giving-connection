class Rack::Attack
  ### Configure Cache ###

  # Configure Rack::Attack to use Redis with namespace and key expiry
  CACHE_PREFIX = "rack_attack".freeze

  # Use Redis for storing throttle data with automatic key expiry
  Rack::Attack.cache.store = Redis::Store.new(
    url: ENV.fetch("REDISCLOUD_URL") { ENV.fetch("REDIS_URL", "redis://localhost:6379/0") },
    namespace: CACHE_PREFIX,
    expires_in: 1.day # Global TTL for keys
  )

  class << self
    private

    # Helper method to create Redis keys with size limits
    def cache_key_with_limits(key, max_size = 1024)
      # Ensure key doesn't exceed maximum size to prevent memory issues
      key = key.to_s
      key = key[0...max_size] if key.length > max_size
      "#{CACHE_PREFIX}:#{key}"
    end
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
  # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    cache_key_with_limits("ip:#{req.ip}") unless req.path.start_with?("/assets")
  end

  ### Prevent Registration Spam ###

  # Throttle new account registrations by IP
  # Allow 3 registrations per IP per hour
  throttle("registrations/ip", limit: 3, period: 1.hour) do |req|
    if req.path == "/users" && req.post?
      cache_key_with_limits("registration:ip:#{req.ip}")
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
  # (domains not in the allowed list)
  throttle("registrations/suspicious_email_domain", limit: 2, period: 1.hour) do |req|
    if req.path == "/users" && req.post? && req.params["user"].present?
      email = req.params["user"]["email"].to_s
      domain = email.split("@").last.to_s.downcase if email.include?("@")
      if domain.present? && !ALLOWED_EMAIL_PROVIDERS.include?(domain)
        cache_key_with_limits("registration:domain:#{domain}")
      end
    end
  end

  # Return a custom error message for throttled registration attempts
  Rack::Attack.throttled_responder = lambda do |env|
    now = Time.zone.now
    match_data = env["rack.attack.match_data"]
    period = match_data[:period]
    retry_after = period - (now.to_i % period)

    headers = {
      "Content-Type" => "application/json",
      "Retry-After" => retry_after.to_s
    }

    [
      429,
      headers,
      [{
        error: "Too many attempts. Please try again in #{retry_after} seconds.",
        retry_after: retry_after
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
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:logins/ip:#{req.ip}"
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/login" && req.post?
      req.ip
    end
  end

  # Throttle POST requests to /login by email param
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:logins/email:#{normalized_email}"
  #
  # Note: This creates a problem where a malicious user could intentionally
  # throttle logins for another user and force their login requests to be
  # denied, but that's not very common and shouldn't happen to you. (Knock
  # on wood!)
  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/login" && req.post?
      # Normalize the email, using the same logic as your authentication process, to
      # protect against rate limit bypasses. Return the normalized email if present, nil otherwise.
      req.params["email"].to_s.downcase.gsub(/\s+/, "").presence
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
  if defined?(Rails.cache) && Rails.cache.respond_to?(:redis)
    Rails.cache.redis.expire(CACHE_PREFIX, 24.hours.to_i)
  end
end
