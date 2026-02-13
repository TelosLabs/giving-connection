# frozen_string_literal: true

class HealthController < ActionController::Base
  # Skip Rack::Attack throttling for health checks
  if defined?(Rack::Attack)
    Rack::Attack.safelist("health-check") do |req|
      req.path == "/up"
    end
  end

  def show
    ActiveRecord::Base.connection.execute("SELECT 1")
    render plain: "OK", status: :ok
  rescue StandardError => e
    Rails.logger.error("[HealthCheck] #{e.class}: #{e.message}")
    render plain: "Service Unavailable", status: :service_unavailable
  end
end
