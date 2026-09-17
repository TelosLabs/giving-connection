# frozen_string_literal: true

class SearchesController < ApplicationController
  skip_before_action :authenticate_user!

  SEARCH_PILLS_FRAME_ID = "search-pills"

  def show
    if !request.referrer&.include?(search_url) && params["search"].blank?
      @search = Search.new

      authorize @search
      render "_preview" and return
    end

    set_search_pills_data
    @search = params["search"].present? ? Search.new(create_params.to_h.merge(location_params)) : Search.new(location_params)

    # _preview's "search-pills" and "search-locations" turbo-frames both declare
    # src: search_path() and Turbo requests each independently, so this action
    # runs twice per cold landing regardless of what either frame actually
    # needs. The search-pills frame only renders SearchPills::Component (built
    # from set_search_pills_data above) -- computing and paginating the full
    # search here too, just to have Turbo keep only the #search-pills fragment
    # and discard the rest, doubled the cost of every cold landing.
    if turbo_frame_request_id == SEARCH_PILLS_FRAME_ID
      authorize @search
      render partial: "search_pills_frame" and return
    end

    @search.save

    results = @search.results
    @all_result_ids = results.pluck(:id) # Capture all IDs before pagination
    @pagy, @results = pagy(results.includes(organization: [:causes, {logo_attachment: :blob}], phone_number: []))
    @map_locations = results.public_address.besides_po_boxes.to_a

    authorize @search

    track_search_term
  end

  private

  # First-party analytics. Runs server-side so it survives ad blockers and so the
  # result count — the whole point, since it makes zero-result searches visible —
  # is recorded from the same data that rendered the page.
  def track_search_term
    tracked = Searches::Tracker.call(
      keyword: @search.keyword,
      results_count: @all_result_ids.size,
      origin: params[:search_origin],
      city: @search.city,
      state: @search.state,
      filtered: filters_applied?,
      previous_keyword: session[:last_tracked_search_term]
    )
    session[:last_tracked_search_term] = tracked.normalized_keyword if tracked
  end

  def filters_applied?
    boolean = ActiveModel::Type::Boolean.new
    @search.causes.present? || @search.services.present? ||
      @search.beneficiary_groups.present? || @search.scope_of_work.present? ||
      boolean.cast(@search.open_now) || boolean.cast(@search.open_weekends) || false
  end

  def create_params
    params.require(:search).permit(:distance, :city, :state, :lat, :lon,
      :open_now, :open_weekends, :keyword, :scope_of_work,
      :zipcode, causes: [], services: {}, beneficiary_groups: {}, give: [])
  end

  def location_params
    {
      city: @current_location[:city],
      state: @current_location[:state],
      lat: @current_location[:latitude],
      lon: @current_location[:longitude]
    }
  end

  def set_search_pills_data
    set_causes
    set_services
    set_beneficiary_groups
  end

  def set_causes
    @top_10_causes = Cause.top(limit: 10)
    @causes = Rails.cache.fetch("search_pills/causes", expires_in: 1.day) { Cause.all.pluck(:name) }
  end

  def set_services
    @top_10_services = Service.top(limit: 10)
    @services = Rails.cache.fetch("search_pills/services", expires_in: 1.day) do
      Cause.all.each_with_object({}) { |cause, hash| hash[cause.name] = cause.services.map(&:name) }
    end
  end

  def set_beneficiary_groups
    @top_10_beneficiary_subcategories = BeneficiarySubcategory.top(limit: 10)
    @beneficiary_groups = Rails.cache.fetch("search_pills/beneficiary_groups", expires_in: 1.day) do
      BeneficiaryGroup.all.each_with_object({}) { |group, hash| hash[group.name] = group.beneficiary_subcategories.map(&:name) }
    end
  end
end
