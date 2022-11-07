# frozen_string_literal: true

class CausesController < ApplicationController
  def index
    @causes = policy_scope(Cause)
    authorize @causes
  end

  def show
    @cause = Cause.find_by(name: params[:name])
    authorize @cause
    @locations = Location.location_with_cause(@cause)
  end
end
