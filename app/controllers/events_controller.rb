class EventsController < ApplicationController

  skip_before_action :authenticate_user!, only: [:index, :create, :update, :destroy]
  skip_before_action :verify_authenticity_token, only: [:index, :create, :update, :destroy]
  after_action :skip_authorization, only: [:index, :create, :update, :destroy]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped, only: [:index]

  def index
    org_id = params[:org_id] || params[:orgId]
    puts "Params: #{params.to_json}"
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
  
  def new
    @my_organizations = current_user.administrated_organizations
    @organization = @my_organizations.first
    params[:org_id] ||= @organization.id
    @event = Event.new
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

  def update
   
    event = Event.find_by(id: params[:id])

    unless event
      
      return render json: { error: "Event not found" }, status: :not_found
    end

    
    if event.update(event_params)
      
      render json: { message: "Event updated successfully", event: event }, status: :ok
    else
      
      render json: { error: "Failed to update event", details: event.errors.full_messages }, status: :unprocessable_entity
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
      ).tap do |whitelisted|
        # Allow end_time to be nil for create and update actions
        whitelisted[:end_time] = nil if whitelisted[:end_time].blank?
      end
  end
end
