# frozen_string_literal: true

require "rack/attack"

# Rack::Attack is enabled by default in the test environment, and its general
# `req/ip` throttle (300 requests per 5 minutes) counts every request the
# suite makes from 127.0.0.1 into one shared bucket. Request specs therefore
# competed for a global budget: adding examples to one file could push an
# unrelated file over the limit and turn its assertions into 429s, which is
# both confusing to debug and dependent on execution order.
#
# Disable it around every request example. The dedicated throttle spec
# re-enables it in its own `around` hook, which RSpec nests *inside* this one,
# so that spec still exercises the real throttles.
RSpec.configure do |config|
  config.around(:each, type: :request) do |example|
    was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false
    example.run
  ensure
    Rack::Attack.enabled = was_enabled
  end
end
