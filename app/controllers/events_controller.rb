class EventsController < ApplicationController
  
  skip_before_action :authenticate_user!, only: [:create]
  skip_before_action :verify_authenticity_token, only: [:create]
  after_action :skip_authorization, only: [:create]

  def index
    org_id = params[:org_id] || params[:orgId]
    if org_id.blank?
      return render json: { error: "orgId parameter is required" }, status: :bad_request
    end
  
    organization = Organization.find_by(id: org_id)
    unless organization
      return render json: { error: "Organization not found" }, status: :not_found
    end
  
    events = organization.events.order(:start_time)
    render json: { events: events }, status: :ok
  end
  

  def create
    organization = Organization.find_by(id: params[:org_id])

    unless organization
      return render json: { error: "Organization not found" }, status: :not_found
    end

    event = organization.events.build(event_params)

    if event.save
      render json: { message: "Event created successfully", event: event }, status: :created
    else
      render json: { message: "Event creation failed", errors: event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    event = Event.find_by(id: params[:id])
  
    unless event
      return render json: { error: "Event not found" }, status: :not_found
    end
  
    if event.destroy
      render json: { message: "Event deleted successfully" }, status: :ok
    else
      render json: { error: "Failed to delete event" }, status: :unprocessable_entity
    end
  end

  private

  def event_params
    params.require(:event).permit(
      :title, :description, :link, :image_link, :location,
      :published, :isRecurring, :start_time, :end_time,
      type_of_event: [], tags: [], categories: [], subcategories: []
    )
  end
end
