class EventsController < ApplicationController

  skip_before_action :authenticate_user!, only: [:index, :create, :update, :destroy]
  skip_before_action :verify_authenticity_token, only: [:index, :create, :update, :destroy]
  after_action :skip_authorization, only: [:index, :create, :update, :destroy]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped, only: [:index]

  def index
    org_id = params[:org_id] || params[:orgId] || ''

    # If no org_id is provided, return all events
    if org_id.blank?
      return render json: { events: Event.where(published: true).order(:start_time), organizations: Organization.all }, status: :ok
    end

    organization = Organization.find_by(id: org_id)
    unless organization
      return render json: { error: "Organization not found" }, status: :not_found
    end
    
    events = organization.events.order(:start_time)
    
    # If user timezone is provided, convert the times for display
    if params[:timezone].present?
      events_with_timezone = events.map do |event|
        event_hash = event.as_json
        event_hash['start_time'] = event.start_time&.in_time_zone(params[:timezone])
        event_hash['end_time'] = event.end_time&.in_time_zone(params[:timezone])
        event_hash['timezone'] = params[:timezone]
        event_hash
      end
      
      render json: { events: events_with_timezone, organization: organization }, status: :ok
    else
      # If no timezone provided, just return the events with UTC times
      render json: { events: events, organization: organization, timezone: "UTC" }, status: :ok
    end
  end
  
  def new
    @event = Event.new
    @organization = Organization.find(params[:org_id]) if params[:org_id].present?
    @event_is_remote = true
    @user_timezone = params[:timezone] || 'UTC'
    render :form
  end
  
  def edit
    @event = Event.find(params[:id])
    @organization = @event.organization
    @user_timezone = params[:timezone] || 'UTC'
    
    if @event.start_time.present?
      # Convert UTC times to user's timezone for display
      local_start_time = @event.start_time.in_time_zone(@user_timezone)
      local_end_time = @event.end_time&.in_time_zone(@user_timezone)
      
      @event_date = local_start_time.to_date
      @event_start_time = local_start_time.strftime("%H:%M")
      @event_end_time = local_end_time&.strftime("%H:%M")
    end
    
    @event_is_remote = (@event.location == "Remote" || @event.location == "Virtual Event" || @event.location == nil || @event.location == "")
    render :form
  end

  def show
    @event = Event.find(params[:id])
    @organization = @event.organization
    @user_timezone = params[:timezone] || 'UTC'
    
    if @event.start_time.present?
      # Convert UTC times to user's timezone for display
      local_start_time = @event.start_time.in_time_zone(@user_timezone)
      local_end_time = @event.end_time&.in_time_zone(@user_timezone)
      
      @event_date = local_start_time.to_date
      @event_start_time = local_start_time.strftime("%H:%M")
      @event_end_time = local_end_time&.strftime("%H:%M")
    end
    
    @event_is_remote = (@event.location == "Remote" || @event.location == "Virtual Event" || @event.location == nil || @event.location == "")
    @readonly = true
    
    respond_to do |format|
      format.html { render :form }
      format.json { 
        # For JSON response, convert times to the user's timezone
        event_json = @event.as_json
        event_json['start_time'] = @event.start_time&.in_time_zone(@user_timezone)
        event_json['end_time'] = @event.end_time&.in_time_zone(@user_timezone)
        event_json['timezone'] = @user_timezone
        
        render json: { event: event_json } 
      }
    end
  end

  def publish
    event = Event.find(params[:id])
    if event.update(published: true)
      render json: { message: "Event published successfully" }, status: :ok
    else
      render json: { message: "Failed to publish event", errors: event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def discover
    if params[:id]
      # Logic for discover with specific event
      @event = Event.find(params[:id])
      @organization = @event.organization
      # Take next 3 upcoming events for this org
      @upcoming_events = Event.where(organization_id: @organization.id, published: true).order(:start_time).limit(3)
      render :event
    else
      # Logic for discover without specific event
      @events = Event.where(published: true).order(:start_time)
      @events = @events.select { |event| event.start_time > Time.now }
      render :discover
    end
  end

  def create
    organization = Organization.find_by(id: params[:org_id])
    user_timezone = params[:timezone] || 'UTC'

    unless organization
      return render json: { error: "Organization not found" }, status: :not_found
    end

    # Create a copy of the parameters we can modify
    create_params = event_params.to_h
    
    # Process the date and time fields from the form if they exist
    if params[:event][:date].present? && params[:event][:start_time].present?
      date = params[:event][:date]
      start_time = params[:event][:start_time]
      
      # Parse the local time with the user's timezone
      local_start_time = Time.use_zone(user_timezone) do
        Time.zone.parse("#{date} #{start_time}")
      end
      
      # Convert to UTC for storage
      create_params[:start_time] = local_start_time.utc
      
      # Handle end time if present
      if params[:event][:end_time].present?
        end_time = params[:event][:end_time]
        
        # Parse the local time with the user's timezone
        local_end_time = Time.use_zone(user_timezone) do
          Time.zone.parse("#{date} #{end_time}")
        end
        
        # Convert to UTC for storage
        create_params[:end_time] = local_end_time.utc
      end
    elsif params[:event][:start_time].present? # For JSON API
      # Try to parse ISO8601 format with timezone info
      begin
        create_params[:start_time] = Time.parse(params[:event][:start_time]).utc
        create_params[:end_time] = Time.parse(params[:event][:end_time]).utc if params[:event][:end_time].present?
      rescue ArgumentError
        # If the time string doesn't include timezone info, use the provided timezone
        start_time = Time.use_zone(user_timezone) do
          Time.zone.parse(params[:event][:start_time])
        end
        create_params[:start_time] = start_time.utc
        
        if params[:event][:end_time].present?
          end_time = Time.use_zone(user_timezone) do
            Time.zone.parse(params[:event][:end_time])
          end
          create_params[:end_time] = end_time.utc
        end
      end
    end
    
    # Handle the remote/location fields
    if params[:event][:remote] == "true"
      create_params[:location] = "Remote"
    elsif params[:event][:address].present?
      create_params[:location] = params[:event][:address]
    end
    
    # Process event types
    create_params[:type_of_event] = JSON.parse(params[:event][:type_of_event]) if params[:event][:type_of_event].present?
    
    # Set whether it's a draft or not
    create_params[:published] = params[:event][:is_draft] != "true"
    
    # Set recurring flag
    create_params[:isRecurring] = params[:event][:recurring] == "true"

    event = organization.events.build(create_params)

    if event.save
      # Convert times back to user's timezone for the response
      event_json = event.as_json
      event_json['start_time'] = event.start_time&.in_time_zone(user_timezone)
      event_json['end_time'] = event.end_time&.in_time_zone(user_timezone)
      event_json['timezone'] = user_timezone
      
      render json: { message: "Event created successfully", event: event_json }, status: :created
    else
      render json: { message: "Event creation failed", errors: event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
   
    event = Event.find_by(id: params[:id])

    if params[:event][:address].present?
      params[:event][:location] = params[:event][:address]
    end

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
      :title, :description, :link, :image, :location,
      :published, :isRecurring, :start_time, :end_time,
      type_of_event: [], tags: [], categories: [], subcategories: []
      ).tap do |whitelisted|
        # Allow end_time to be nil for create and update actions
        whitelisted[:end_time] = nil if whitelisted[:end_time].blank?
      end
  end
end