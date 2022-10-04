# frozen_string_literal: true

class SearchesController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_causes, only: [:show]
  before_action :set_services, only: [:show]
  before_action :set_beneficiary_groups, only: [:show]
  before_action :verify_search_params, only: [:show]

  def show
    @search = params['search'].present? ? Search.new(create_params) : Search.new
    @search.save
    @pagy, @results = pagy(@search.results)
    puts @search.errors.full_messages if @search.results.any?
    authorize @search
  end

  def create_params
    params.require(:search).permit(:distance, :city, :state, :lat, :lon,
                                   :open_now, :open_weekends, :keyword,
                                   :zipcode, causes: [], services: {}, beneficiary_groups: {})
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
    causes_count = {}
    Location.all.each do |location|
      location.causes.each do |cause|
        causes_count[cause] = causes_count[cause].to_i + 1
      end
    end
    arr = causes_count.sort_by { |cause, count| count }.reverse.first(10)
    @top_10_causes = arr.map { |cause, count| cause }
    @causes = helpers.take_off_intersection_from_array(@top_10_causes.pluck(:name), Cause.all.pluck(:name))
  end

  def set_services
    @services = {}
    services_count = {}
    Location.all.each do |location|
      location.services.each do |service|
        services_count[service] = services_count[service].to_i + 1
      end
    end
    arr = services_count.sort_by { |service, count| count }.reverse.first(10)
    @top_10_services = arr.map { |service, count| service }
    Cause.all.each do |cause|
      @services[cause.name] = helpers.take_off_intersection_from_array(@top_10_services.pluck(:name), cause.services.map(&:name))
    end
  end

  def set_beneficiary_groups
    @beneficiary_groups = {}
    beneficiary_subcategories_count = {}
    Organization.all.each do |org|
      org.beneficiary_subcategories.each do |beneficiary_subcategory|
        beneficiary_subcategories_count[beneficiary_subcategory] = beneficiary_subcategories_count[beneficiary_subcategory].to_i + 1
      end
    end
    arr = beneficiary_subcategories_count.sort_by { |beneficiary_subcategory, count| count }.reverse.first(10)
    @top_10_beneficiary_subcategories = arr.map { |beneficiary_subcategory, count| beneficiary_subcategory }
    BeneficiaryGroup.all.each do |group|
      @beneficiary_groups[group.name] = helpers.take_off_intersection_from_array(@top_10_beneficiary_subcategories.pluck(:name), group.beneficiary_subcategories.map(&:name))
    end
  end
end
