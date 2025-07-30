# frozen_string_literal: true

class SearchExportsController < ApplicationController
  include Locationable
  
  skip_before_action :verify_authenticity_token, only: [:create, :test, :test_no_auth]
  skip_before_action :authenticate_user!, only: [:test_no_auth]
  before_action :authenticate_user!, only: [:create]
  before_action :set_search_results, only: [:create]

  def test
    # Simple test to verify download works
    csv_content = "Nonprofit Name,Description,Address,City,State,Zip Code,Phone Number,Email,Website,Causes,Verified,Profile Link\nTest Organization,Test Description,123 Test St,Test City,TN,12345,555-1234,test@example.com,http://test.com,Health,Yes,http://localhost:3000/locations/1"
    
    send_data(
      csv_content,
      filename: "test_download_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
      type: 'text/csv',
      disposition: 'attachment'
    )
  end

  def test_no_auth
    # Test method that doesn't require authentication
    Rails.logger.info "=== TEST NO AUTH CALLED ==="
    Rails.logger.info "Params: #{params.inspect}"
    
    # Skip authorization for test method
    skip_authorization
    
    csv_content = "Test CSV Content\nRow 1,Value 1\nRow 2,Value 2"
    
    send_data(
      csv_content,
      filename: "test_no_auth_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
      type: 'text/csv',
      disposition: 'attachment'
    )
  end

  def test_simple
    Rails.logger.info "=== TEST SIMPLE CALLED ==="
    Rails.logger.info "Params: #{params.inspect}"
    
    # Skip authorization for test method
    skip_authorization
    
    render plain: "Test simple endpoint works! Params: #{params.inspect}"
  end

  def download
    Rails.logger.info "=== DOWNLOAD ACTION CALLED ==="
    Rails.logger.info "Params: #{params.inspect}"
    
    # Skip authorization for download action
    skip_authorization
    
    begin
      # Get search parameters from URL params
      search_params = extract_search_params_from_url
      
      # Recreate the search to get the same results as the current page
      search_params_with_location = search_params.merge(location_params)
      @search = Search.new(search_params_with_location)
      @search.save
      
      # Get all results (not paginated) for export
      @search_results = @search.results.includes(
        organization: [:causes],
        phone_number: []
      )
      
      # Generate CSV content
      csv_content = SearchResultsExporter.call(@search_results, search_params)
      
      # Generate filename with timestamp
      filename = generate_filename(search_params)
      
      Rails.logger.info "Generated filename: #{filename}"
      Rails.logger.info "CSV content length: #{csv_content.length}"
      
      # Send CSV file
      send_data(
        csv_content,
        filename: filename,
        type: 'text/csv',
        disposition: 'attachment'
      )
    rescue => e
      Rails.logger.error "Error in search export: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render plain: "Error generating download: #{e.message}"
    end
  end

  def create
    Rails.logger.info "=== SEARCH EXPORT CONTROLLER CALLED ==="
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "Current user: #{current_user&.email}"
    Rails.logger.info "Request method: #{request.method}"
    Rails.logger.info "Request path: #{request.path}"
    Rails.logger.info "Content-Type: #{request.content_type}"
    Rails.logger.info "Accept: #{request.accept}"
    
    # Skip authorization for download action - user is already authenticated
    skip_authorization
    
    begin
      # Generate CSV content
      csv_content = SearchResultsExporter.call(@search_results, search_params)
      
      # Generate filename with timestamp
      filename = generate_filename(search_params)
      
      Rails.logger.info "Generated filename: #{filename}"
      Rails.logger.info "CSV content length: #{csv_content.length}"
      
      # Send CSV file
      send_data(
        csv_content,
        filename: filename,
        type: 'text/csv',
        disposition: 'attachment'
      )
    rescue => e
      Rails.logger.error "Error in search export: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  private

  def set_search_results
    # Recreate the search to get the same results as the current page
    search_params_with_location = search_params.merge(location_params)
    @search = Search.new(search_params_with_location)
    @search.save
    
    # Get all results (not paginated) for export
    @search_results = @search.results.includes(
      organization: [:causes],
      phone_number: []
    )
  end

  def search_params
    if params[:search_params].present?
      # Parse the JSON from the data attribute and convert to ActionController::Parameters
      parsed_params = JSON.parse(params[:search_params])
      ActionController::Parameters.new(parsed_params).permit(
        :distance, :city, :state, :lat, :lon,
        :open_now, :open_weekends, :keyword, :scope_of_work,
        :zipcode, causes: [], services: {}, beneficiary_groups: {}
      )
    elsif params[:data_search_params].present?
      # Parse the JSON from the data attribute (link_to approach) and convert to ActionController::Parameters
      parsed_params = JSON.parse(params[:data_search_params])
      ActionController::Parameters.new(parsed_params).permit(
        :distance, :city, :state, :lat, :lon,
        :open_now, :open_weekends, :keyword, :scope_of_work,
        :zipcode, causes: [], services: {}, beneficiary_groups: {}
      )
    elsif params[:data].present? && params[:data][:search_params].present?
      # Parse the JSON from the data attribute (link_to approach) and convert to ActionController::Parameters
      parsed_params = JSON.parse(params[:data][:search_params])
      ActionController::Parameters.new(parsed_params).permit(
        :distance, :city, :state, :lat, :lon,
        :open_now, :open_weekends, :keyword, :scope_of_work,
        :zipcode, causes: [], services: {}, beneficiary_groups: {}
      )
    else
      # Fallback to the original method
      params.require(:search).permit(
        :distance, :city, :state, :lat, :lon,
        :open_now, :open_weekends, :keyword, :scope_of_work,
        :zipcode, causes: [], services: {}, beneficiary_groups: {}
      )
    end
  rescue JSON::ParserError => e
    Rails.logger.error "JSON parsing error: #{e.message}"
    Rails.logger.error "Raw search_params: #{params[:search_params]}"
    # If JSON parsing fails, try the original method
    params.require(:search).permit(
      :distance, :city, :state, :lat, :lon,
      :open_now, :open_weekends, :keyword, :scope_of_work,
      :zipcode, causes: [], services: {}, beneficiary_groups: {}
    )
  rescue => e
    Rails.logger.error "Unexpected error in search_params: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    # Return empty permitted params as fallback
    ActionController::Parameters.new({}).permit(
      :distance, :city, :state, :lat, :lon,
      :open_now, :open_weekends, :keyword, :scope_of_work,
      :zipcode, causes: [], services: {}, beneficiary_groups: {}
    )
  end

  def location_params
    {
      city: @current_location[:city],
      state: @current_location[:state],
      lat: @current_location[:latitude],
      lon: @current_location[:longitude]
    }
  end

  def generate_filename(search_params = nil)
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    if search_params && search_params[:keyword].present?
      keyword = "_#{search_params[:keyword].parameterize}"
    else
      keyword = ""
    end
    "search_results#{keyword}_#{timestamp}.csv"
  end

  def extract_search_params_from_url
    if params[:search_params].present?
      # Parse the JSON from the URL parameter and convert to ActionController::Parameters
      parsed_params = JSON.parse(params[:search_params])
      ActionController::Parameters.new(parsed_params).permit(
        :distance, :city, :state, :lat, :lon,
        :open_now, :open_weekends, :keyword, :scope_of_work,
        :zipcode, causes: [], services: {}, beneficiary_groups: {}
      )
    else
      # Fallback to empty permitted params
      ActionController::Parameters.new({}).permit(
        :distance, :city, :state, :lat, :lon,
        :open_now, :open_weekends, :keyword, :scope_of_work,
        :zipcode, causes: [], services: {}, beneficiary_groups: {}
      )
    end
  rescue JSON::ParserError => e
    Rails.logger.error "JSON parsing error: #{e.message}"
    Rails.logger.error "Raw search_params: #{params[:search_params]}"
    # Return empty permitted params as fallback
    ActionController::Parameters.new({}).permit(
      :distance, :city, :state, :lat, :lon,
      :open_now, :open_weekends, :keyword, :scope_of_work,
      :zipcode, causes: [], services: {}, beneficiary_groups: {}
    )
  end
end 