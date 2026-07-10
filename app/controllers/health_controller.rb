# frozen_string_literal: true

# Inherits from ActionController::Base intentionally to bypass
# Devise authentication and Pundit authorization for health checks.
class HealthController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def show
    ActiveRecord::Base.connection.execute("SELECT 1")
    render plain: "OK", status: :ok
  rescue => e
    Rails.logger.error("[HealthCheck] #{e.class}: #{e.message}")
    render plain: "Service Unavailable", status: :service_unavailable
  end
end
