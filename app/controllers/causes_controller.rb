# frozen_string_literal: true

class CausesController < ApplicationController
  skip_before_action :authenticate_user!
  
  def index
    @causes = policy_scope(Cause)
    authorize @causes
  end

  def show
    @cause = Cause.find_by(name: params[:name])
    authorize @cause
    filtered_locations = Location.locations_with_(@cause)
    @locations_by_services = Location.sort_by_more_services(filtered_locations).includes(:phone_number, images_attachments: [:blob]).includes(organization: [:causes, {cover_photo_attachment: :blob, logo_attachment: :blob}])
  end
end
