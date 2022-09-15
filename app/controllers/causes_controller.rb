# frozen_string_literal: true

class CausesController < ApplicationController
  def index
    @causes = policy_scope(Cause)
    authorize @causes
  end

  def show
    @cause = Cause.find_by(name: params[:name])
    authorize @cause
    @locations = location_with_cause(@cause)
  end

  private

  def location_with_cause(cause)
    sort_by_more_services(Location.joins(:causes).where(causes: { id: cause.id }))
  end

  def sort_by_more_services(filtered_locations)
    filtered_locations.joins(:services).group(:id).order('count(services.id) DESC')
  end
end
