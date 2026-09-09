# frozen_string_literal: true

class SearchesController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    if !request.referrer&.include?(search_url) && params["search"].blank?
      @search = Search.new
      render "_preview"
    end

    set_search_pills_data
    @search = params["search"].present? ? Search.new(create_params.to_h.merge(location_params)) : Search.new(location_params)
    @search.save
    @all_result_ids = @search.results.pluck(:id)  # Capture all IDs before pagination
    @pagy, @results = pagy(@search.results)

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
      :zipcode, causes: [], services: {}, beneficiary_groups: {})
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
    @causes = Cause.all.pluck(:name)
  end

  def set_services
    @services = {}
    @top_10_services = Service.top(limit: 10)
    Cause.all.each do |cause|
      @services[cause.name] = cause.services.map(&:name)
    end
  end

  def set_beneficiary_groups
    @beneficiary_groups = {}
    @top_10_beneficiary_subcategories = BeneficiarySubcategory.top(limit: 10)
    BeneficiaryGroup.all.each do |group|
      @beneficiary_groups[group.name] = group.beneficiary_subcategories.map(&:name)
    end
  end
end
