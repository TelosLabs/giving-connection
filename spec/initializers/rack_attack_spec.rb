require "rails_helper"

RSpec.describe "Rack::Attack configuration" do
  describe Rack::Attack::Request do
    describe "#remote_ip" do
      it "uses the proxy-aware ActionDispatch remote ip when present" do
        # Behind kamal-proxy REMOTE_ADDR is the proxy's private Docker IP and the
        # real visitor is resolved into action_dispatch.remote_ip.
        request = described_class.new(
          "action_dispatch.remote_ip" => "203.0.113.7",
          "REMOTE_ADDR" => "172.18.0.5"
        )

        expect(request.remote_ip).to eq("203.0.113.7")
      end

      it "falls back to the raw ip when ActionDispatch has not resolved one" do
        request = described_class.new("REMOTE_ADDR" => "198.51.100.9")

        expect(request.remote_ip).to eq("198.51.100.9")
      end
    end
  end

  describe "throttled_responder" do
    def message_for(matched)
      request = Rack::Attack::Request.new(
        "rack.attack.matched" => matched,
        "rack.attack.match_data" => {period: 300, limit: 1},
        "action_dispatch.remote_ip" => "203.0.113.7"
      )
      _status, _headers, body = Rack::Attack.throttled_responder.call(request)
      JSON.parse(body.first)
    end

    it "returns a 429 with a Retry-After header" do
      request = Rack::Attack::Request.new(
        "rack.attack.matched" => "req/ip",
        "rack.attack.match_data" => {period: 300, limit: 1}
      )
      status, headers, _body = Rack::Attack.throttled_responder.call(request)

      expect(status).to eq(429)
      expect(headers["Retry-After"].to_i).to be_between(1, 300)
    end

    it "labels the general navigation throttle as a generic request limit, not a registration error" do
      # Regression: the responder used to key off the discriminator (the IP), so
      # every IP-based throttle — including req/ip firing on ordinary browsing —
      # surfaced the registration message.
      body = message_for("req/ip")

      expect(body["error"]).to eq("Too many requests. Please try again in #{body["retry_after"]} seconds.")
      expect(body["error"]).not_to include("registration")
      expect(body["throttle_type"]).to eq("req/ip")
    end

    it "labels the registration IP throttle as a registration error" do
      body = message_for("registrations/ip")

      expect(body["error"]).to include("Too many registration attempts from this IP address")
    end

    it "labels the suspicious email domain throttle distinctly" do
      body = message_for("registrations/suspicious_email_domain")

      expect(body["error"]).to include("email domain are temporarily restricted")
    end

    it "labels login throttles as login errors" do
      expect(message_for("logins/ip")["error"]).to include("Too many login attempts")
      expect(message_for("logins/email")["error"]).to include("Too many login attempts")
    end
  end

  describe ".feedback_discriminator" do
    def request_for(path: "/feedbacks", method: "POST", user: nil)
      env = {
        "PATH_INFO" => path,
        "REQUEST_METHOD" => method,
        "action_dispatch.remote_ip" => "203.0.113.7"
      }
      env["warden"] = instance_double(Warden::Proxy, user: user) if user
      Rack::Attack::Request.new(env)
    end

    it "buckets anonymous submissions by client IP" do
      expect(Rack::Attack.feedback_discriminator(request_for)).to eq("203.0.113.7")
    end

    it "buckets signed-in submissions by user id" do
      user = instance_double(User, id: 42)

      expect(Rack::Attack.feedback_discriminator(request_for(user: user))).to eq("user:42")
    end

    it "ignores anything that is not a POST to /feedbacks" do
      expect(Rack::Attack.feedback_discriminator(request_for(method: "GET"))).to be_nil
      expect(Rack::Attack.feedback_discriminator(request_for(path: "/organizations"))).to be_nil
    end
  end

  describe "req/ip throttle path exclusions" do
    it "excludes framework-served paths that a single page load fans out into" do
      %w[/assets/app.js /rails/active_storage/blobs/x /packs/y /cable /up].each do |path|
        excluded = Rack::Attack::EXCLUDED_FROM_REQ_THROTTLE.any? { |prefix| path.start_with?(prefix) }
        expect(excluded).to be(true), "expected #{path} to be excluded from req/ip throttle"
      end
    end

    it "still counts real page navigation" do
      excluded = Rack::Attack::EXCLUDED_FROM_REQ_THROTTLE.any? { |prefix| "/organizations".start_with?(prefix) }
      expect(excluded).to be(false)
    end
  end
end
