require 'ostruct'

class EventsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :create, :update, :destroy]
  skip_before_action :verify_authenticity_token, only: [:index, :create, :update, :destroy]
  after_action :skip_authorization, only: [:index, :create, :update, :destroy]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped, only: [:index]

  def index
    org_id = params[:org_id] || params[:orgId] || ""

    # If no org_id is provided, return all events. Called from the discover page's calendar component
    if org_id.blank?
      @events = Event.where(published: true).order(:start_time)
      filter_events

      events_json = @events.map do |event|
        event_hash = event.as_json
        event_hash["allDay"] = event.all_day?
        event_hash
      end

      return render json: {events: @events, organizations: Organization.all}, status: :ok
    end

    organization = Organization.find_by(id: org_id)
    unless organization
      return render json: {error: "Organization not found"}, status: :not_found
    end

    events = organization.events.order(:start_time)

    # If user timezone is provided, convert the times for display
    if @user_timezone.present?
      events_with_timezone = events.map do |event|
        event_hash = event.as_json
        event_hash["start_time"] = event.start_time&.in_time_zone(params[:timezone])
        event_hash["end_time"] = event.end_time&.in_time_zone(params[:timezone])
        event_hash["timezone"] = @user_timezone
        event_hash
      end

      render json: {events: events_with_timezone, organization: organization}, status: :ok
    else
      # If no timezone provided, just return the events with UTC times
      render json: {events: events, organization: organization, timezone: "UTC"}, status: :ok
    end
  end

  def new
    @event = Event.new
    @organization = Organization.find(params[:org_id]) if params[:org_id].present?
    @event_is_remote = true
    render :form
  end

  def edit
    @event = Event.find(params[:id])
    @organization = @event.organization

    times = format_event_times(@event, @user_timezone)
    @event_start_date = times[:start_date]
    @event_end_date = times[:end_date]

    if @event.all_day?
      @event_start_time = ""
      @event_end_time = ""
      @disabled_time_fields = true
    else 
      @event_start_time = times[:start_time].strftime("%H:%M")
      @event_end_time = times[:end_time].strftime("%H:%M")
      @disabled_time_fields = false
    end

    @event_is_remote = @event.location == "Remote" || @event.location == "Virtual Event" || @event.location.nil? || @event.location == "" 
    render :form
  end

  def show
    @event = Event.find(params[:id])
    @organization = @event.organization

    times = format_event_times(@event, @user_timezone)
    @event_start_date = times[:start_date]
    @event_end_date = times[:end_date]
    @event_start_time = times[:start_time].strftime("%H:%M")
    @event_end_time = times[:end_time].strftime("%H:%M")

    @event_is_remote = @event.location == "Remote" || @event.location == "Virtual Event" || @event.location.nil? || @event.location == ""
    @readonly = true

    respond_to do |format|
      format.html { render :form }
      format.json do
        event_json = @event.as_json
        event_json["all_day"] = @event.all_day?
        event_json["start_date"] = times[:start_date]
        event_json["end_date"] = times[:end_date]
        event_json["start_time"] = times[:start_time].strftime("%H:%M")
        event_json["end_time"] = times[:end_time].strftime("%H:%M")
        event_json["allDay"] = params[:event][:all_day] == "true"
        render json: event_json
      end
    end
  end

  def publish
    event = Event.find(params[:id])
    if event.update(published: true)
      render json: {message: "Event published successfully"}, status: :ok
    else
      render json: {message: "Failed to publish event", errors: event.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # Main search point for fetching events from the events discover page
  def discover
    if params[:id]
      # Logic for discover with specific event
      @event = Event.find(params[:id])
      @organization = @event.organization

      # Take next 3 upcoming events for this org
      @upcoming_events = Event.where(organization_id: @organization.id, published: true)
        .where("start_time > ?", Time.zone.now)
        .order(:start_time)
        .limit(3)
      render :event
    else
      # Logic for discover without specific event
      @events = Event.where(published: true)
               .where("start_time > ? OR (all_day = ? AND start_date >= ?)", 
                      Time.zone.now, true, Date.today)
               .order(:start_time)

      if params[:ein].present?
        @organization = Organization.find_by(ein_number: params[:ein])
      end

      # If search query is present, filter events based on the query
      filter_events
      render :explore
    end
  end

  def create
    organization = Organization.find_by(id: params[:org_id])
    user_timezone = @user_timezone

    unless organization
      return render json: {error: "Organization not found"}, status: :not_found
    end

    # Create a copy of the parameters we can modify
    create_params = event_params.to_h

    # build a temporary event object with the params to process times
    temp_event = OpenStruct.new(
    start_date: params[:event][:start_date],
    end_date: params[:event][:end_date],
    start_time: params[:event][:start_time],
    end_time: params[:event][:end_time],
    all_day: params[:event][:all_day] == "true"
    )

    # Use helper method to get properly formatted start_time and end_time
    times = format_event_times(temp_event, user_timezone)

    create_params[:start_time] = times[:start_time].utc if times[:start_time]
    create_params[:end_time] = times[:end_time].utc if times[:end_time]

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

    create_params[:start_date] = params[:event][:start_date]
    create_params[:end_date] = params[:event][:end_date].presence || params[:event][:start_date]
    create_params[:all_day] = params[:event][:all_day] == "true"
    event = organization.events.build(create_params)

    if event.save
      # Convert times back to user's timezone for the response
      event_json = event.as_json
      event_json["start_time"] = times[:start_time]&.in_time_zone(user_timezone)
      event_json["end_time"] = times[:end_time]&.in_time_zone(user_timezone)
      event_json["timezone"] = user_timezone
      event_json["allDay"] = params[:event][:all_day] == "true"

      render json: {message: "Event created successfully", event: event_json}, status: :created
    else
      render json: {message: "Event creation failed", errors: event.errors.full_messages}, status: :unprocessable_entity
    end
  end

  def update
    event = Event.find_by(id: params[:id])

    unless event
      return render json: {error: "Event not found"}, status: :not_found
    end

    # Create a copy of the parameters we can modify
    update_params = event_params.to_h
    user_timezone = @user_timezone

    # build a temp event object to handle all_day / time formatting
    temp_event = OpenStruct.new(
      start_date: params[:event][:start_date],
      end_date: params[:event][:end_date],
      start_time: params[:event][:start_time],
      end_time: params[:event][:end_time],
      all_day: params[:event][:all_day] == "true"
    )

    # Use helper method to get properly formatted start_time and end_time
    times = format_event_times(temp_event, user_timezone)

    update_params[:start_date] = params[:event][:start_date]
    update_params[:end_date] = params[:event][:end_date].presence || params[:event][:start_date]
    update_params[:start_time] = times[:start_time] ? times[:start_time].utc : nil
    update_params[:end_time] =  times[:end_time] ? times[:end_time].utc : nil

    # Handle the remote/location fields
    if params[:event][:remote] == "true"
      update_params[:location] = "Remote"
    elsif params[:event][:address].present?
      update_params[:location] = params[:event][:address]
    end

    # Process event types
    update_params[:type_of_event] = JSON.parse(params[:event][:type_of_event]) if params[:event][:type_of_event].present?

    # Set whether it's a draft or not
    update_params[:published] = params[:event][:is_draft] != "true" if params[:event][:is_draft].present?

    # Set recurring flag
    update_params[:isRecurring] = params[:event][:recurring] == "true" if params[:event][:recurring].present?

    if event.update(update_params)
      # Convert times back to user's timezone for the response
      event_json = event.as_json
      event_json["start_time"] = times[:start_time]&.in_time_zone(user_timezone)
      event_json["end_time"] = times[:end_time]&.in_time_zone(user_timezone)
      event_json["timezone"] = user_timezone

      render json: {message: "Event updated successfully", event: event_json}, status: :ok
    else
      render json: {error: "Failed to update event", details: event.errors.full_messages}, status: :unprocessable_entity
    end
  end

  def destroy
    event = Event.find_by(id: params[:id])

    unless event
      return render json: {error: "Event not found"}, status: :not_found
    end

    if event.destroy
      render json: {message: "Event deleted successfully"}, status: :ok
    else
      render json: {error: "Failed to delete event"}, status: :unprocessable_entity
    end
  end

  private

  def format_event_times(event, timezone)
    if event.all_day?
      start_date = event.start_date
      end_date = event.end_date || start_date
      start_time = nil
      end_time = nil
    elsif event.start_time.present?
      local_start_time = event.start_time.in_time_zone(timezone)
      local_end_time = event.end_time.in_time_zone(timezone)

      start_date = local_start_time.to_date
      end_date = local_end_time&.to_date || start_date
      start_time = local_start_time
      end_time = local_end_time
    else
      start_date = end_date = start_time = end_time = nil
    end

    { start_date: start_date, end_date: end_date, start_time: start_time, end_time: end_time }
  end

  # Used for discover events to filter events based on query params
  def filter_events
    # If an organzation ein is provided, filter events by that organization first
    if params[:ein].present?
      organization = Organization.find_by(ein_number: params[:ein])
      @events = if organization
        @events.select { |event| event.organization_id == organization.id }
      else
        []
      end
    end

    # If user uses search bar, filter events based on the query second
    if params[:query].present?
      @events = @events.select do |event|
        event.title.downcase.include?(params[:query].downcase) ||
          event.description&.downcase&.include?(params[:query].downcase) ||
          event.location&.downcase&.include?(params[:query].downcase) ||
          event.organization.name.downcase.include?(params[:query].downcase)
      end
    end

    # Then, use other filters
    if params[:type_of_event].present?
      types = params[:type_of_event].is_a?(Array) ? params[:type_of_event] : [params[:type_of_event]]
      @events = @events.select do |event|
        event.type_of_event.present? &&
          (types & event.type_of_event).any?
      end
    end

    # Filter by location type
    if params[:location].present?
      locations = params[:location].is_a?(Array) ? params[:location] : [params[:location]]
      @events = @events.select do |event|
        if locations.include?("Virtual")
          event.location == "Remote" || event.location == "Virtual Event"
        elsif locations.include?("In-Person")
          event.location.present? && event.location != "Remote" && event.location != "Virtual Event"
        else
          false
        end
      end
    end

    # Filter by date range
    if params[:daterange].present?
      date_range = parse_date_range(params[:daterange])
      if date_range[:start].present? && date_range[:end].present?

        @events = @events.select do |event|
          # Include events where:
          # - Timed events fall within the range
          # - All-day events overlap the range based on start_date
          (event.start_time && event.start_time >= start_range && event.start_time <= end_range) ||
          (event.all_day? && event.start_date && event.start_date >= start_range.to_date && event.start_date <= end_range.to_date)
        end
      end
    end
  end

  # Helper method to parse date range string
  def parse_date_range(daterange_str)
    parts = daterange_str.split(" - ")
    result = {start: nil, end: nil}

    return result unless parts.length == 2

    begin
      # Parse dates with time information
      user_timezone = @user_timezone

      result[:start] = Time.use_zone(user_timezone) do
        Time.zone.parse(parts[0])
      end

      result[:end] = Time.use_zone(user_timezone) do
        Time.zone.parse(parts[1])
      end
    rescue ArgumentError
      # Return empty result if parsing fails
    end

    result
  end

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
