# frozen_string_literal: true

class SearchExportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_search_results
  before_action :check_export_limit

  include Pundit::Authorization

  def create
    csv_content = SearchResultsExporter.call(@search_results)
    filename = generate_filename

    send_data(
      csv_content,
      filename: filename,
      type: "text/csv",
      disposition: "attachment"
    )
  rescue => e
    Rails.logger.error "Search export failed for user #{current_user.id}: #{e.message}"
    redirect_back(fallback_location: search_path,
      alert: "Sorry, we couldn't generate your download. Please try again.")
  end

  private

  def set_search_results
    # Get the result IDs array from the form submission
    result_ids = Array(params[:result_ids]).compact

    # Validate we have result IDs
    if result_ids.empty?
      redirect_back(fallback_location: search_path,
        alert: "No search results to export.")
      return
    end

    # Create a dummy search object for authorization
    @search = Search.new
    authorize @search

    # Get all results by IDs (no search recreation needed)
    @search_results = Location.where(id: result_ids).includes(
      organization: [:causes],
      phone_number: []
    )
  end

  def generate_filename
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    result_count = @search_results.count
    "search_results_#{result_count}_locations_#{timestamp}.csv"
  end

  def check_export_limit
    # Simple rate limiting: max 10 exports per hour per user
    cache_key = "export_count_#{current_user.id}_#{Time.current.hour}"
    current_count = Rails.cache.read(cache_key) || 0

    if current_count >= 10
      redirect_back(fallback_location: search_path,
        alert: "Export limit reached. Please try again in an hour.")
      return
    end

    Rails.cache.write(cache_key, current_count + 1, expires_in: 1.hour)
  end

  def validate_search_params
    return if search_params.present? && search_params.values.any?(&:present?)

    redirect_back(fallback_location: search_path,
      alert: "No search criteria provided for export.")
  end
end
