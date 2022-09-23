# frozen_string_literal: true

class SearchesController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_causes, only: [:show]
  before_action :set_services, only: [:show]
  before_action :set_beneficiary_groups, only: [:show]
  before_action :verify_search_params, :set_location_in_session, only: [:show]

  def show
    @search = params['search'].present? ? Search.new(create_params) : Search.new(lat: @current_location[:latitude], lon: @current_location[:longitude])
    @search.save
    @pagy, @results = pagy(@search.results)
    puts @search.errors.full_messages if @search.results.any?
    authorize @search
  end

  def create_params
    params
      .require(:search)
      .permit(:distance, :city, :state, :lat, :lon,
              :open_now, :open_weekends, :keyword,
              :zipcode, causes: [], services: {}, beneficiary_groups: {})
      .with_defaults(lat: @current_location[:latitude], lon: @current_location[:longitude])
  end

  def verify_search_params
    @params_applied = params.dig('search', 'causes').present? ||
                      params.dig('search', 'services').present? ||
                      params.dig('search', 'beneficiary_groups').present? ||
                      params.dig('search', 'city').present? ||
                      params.dig('search', 'zipcode').present? ||
                      params.dig('search', 'distance').present? ||
                      params.dig('search', 'open_now').present? ||
                      params.dig('search', 'open_weekends').present?

  end

  private

  def set_causes
    @causes = Cause.all.pluck(:name)
  end

  def set_services
    @services = {}
    Cause.all.each do |cause|
      @services[cause.name] = cause.services.map(&:name)
    end
  end

  def set_beneficiary_groups
    @beneficiary_groups = {}
    BeneficiaryGroup.all.each do |group|
      @beneficiary_groups[group.name] = group.beneficiary_subcategories.map(&:name)
    end
  end

  def set_location_in_session
    session[:current_location] = {
      city: params.dig('search', 'city').presence || @current_location[:city],
      state: params.dig('search', 'state').presence || @current_location[:state],
      country: params.dig('search', 'country').presence || @current_location[:country],
      latitude: params.dig('search', 'lat').presence || @current_location[:latitude],
      longitude: params.dig('search', 'lon').presence || @current_location[:longitude]
    }
  end
end
