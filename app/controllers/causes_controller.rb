# frozen_string_literal: true

class CausesController < ApplicationController
  def index
    @causes = policy_scope(Cause)
    authorize @causes
  end

  def show
    @cause = Cause.find_by(name: params[:name])
    authorize @cause
    filtered_locations = Location.locations_with_(@cause)
    @locations_by_services = Location.sort_by_more_services(filtered_locations)
  end
end
