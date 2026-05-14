# frozen_string_literal: true

require "rails_helper"
require "rack/attack"

# Exercises the new public-quiz throttles (config/initializers/rack_attack.rb):
#   - smart_match/quiz   60 PUT/PATCH/POST per IP per period
#   - smart_match/results 10 GET per IP per period
#
# Test-environment caveats this spec works around:
#   1. rack_attack.rb sets the cache store to a real Redis at boot. We swap to
#      an in-process MemoryStore for the duration of each example so the suite
#      does not depend on a running Redis.
#   2. THROTTLE_PERIODS is frozen at boot (1.second in test). Rack::Attack
#      keys its counters by `(Time.now.to_i / period)`, so any clock tick
#      across the 1-second boundary starts a fresh bucket. We freeze time with
#      `travel_to` so all requests in an example share one bucket.
#   3. `Rack::Attack.cache.reset!` requires `delete_matched`, which MemoryStore
#      supports, so we reset between examples to keep counters isolated.
RSpec.describe "SmartMatch Rack::Attack throttles", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:ip_a) { "1.2.3.4" }
  let(:ip_b) { "5.6.7.8" }

  around do |example|
    original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
    travel_to(Time.utc(2026, 1, 1, 12, 0, 0)) do
      example.run
    end
  ensure
    Rack::Attack.cache.store = original_store
  end

  describe "smart_match/quiz throttle (60/period/IP)" do
    it "allows 60 requests then throttles the 61st from the same IP" do
      60.times do |i|
        put smart_match_quiz_path, params: {user_type: "donor"}, env: {"REMOTE_ADDR" => ip_a}
        expect(response.status).to satisfy("be allowed on request #{i + 1}, got #{response.status}") { |s| s == 302 || s == 200 }
      end

      put smart_match_quiz_path, params: {user_type: "donor"}, env: {"REMOTE_ADDR" => ip_a}
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "smart_match/results throttle (10/period/IP)" do
    it "allows 10 requests then throttles the 11th from the same IP" do
      10.times do |i|
        get smart_match_result_path, env: {"REMOTE_ADDR" => ip_a}
        expect(response.status).to satisfy("be allowed on request #{i + 1}, got #{response.status}") { |s| (200..399).cover?(s) }
      end

      get smart_match_result_path, env: {"REMOTE_ADDR" => ip_a}
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "throttle key isolation by IP" do
    it "still admits requests from a different IP after the first IP is throttled" do
      # Exhaust quiz throttle from ip_a.
      60.times do
        put smart_match_quiz_path, params: {user_type: "donor"}, env: {"REMOTE_ADDR" => ip_a}
      end
      put smart_match_quiz_path, params: {user_type: "donor"}, env: {"REMOTE_ADDR" => ip_a}
      expect(response).to have_http_status(:too_many_requests)

      # ip_b has its own bucket and should be allowed.
      put smart_match_quiz_path, params: {user_type: "donor"}, env: {"REMOTE_ADDR" => ip_b}
      expect(response.status).not_to eq(429)
    end
  end
end
