# frozen_string_literal: true

class HealthController < ActionController::Base
  def show
    ActiveRecord::Base.connection.execute("SELECT 1")
    render plain: "OK", status: :ok
  rescue StandardError
    render plain: "Service Unavailable", status: :service_unavailable
  end
end
