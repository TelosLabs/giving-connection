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
    @top_10_causes = Cause.top_10_causes
    @causes = helpers.take_off_intersection_from_array(@top_10_causes.pluck(:name), Cause.all.pluck(:name))
  end

  def set_services
    @services = {}
    @top_10_services = Service.top_10_services
    Cause.all.each do |cause|
      @services[cause.name] = helpers.take_off_intersection_from_array(@top_10_services.pluck(:name), cause.services.map(&:name))
    end
  end

  def set_beneficiary_groups
    @beneficiary_groups = {}
    @top_10_beneficiary_groups = BeneficiarySubcategory.top_10_beneficiary_groups
    BeneficiaryGroup.all.each do |group|
      @beneficiary_groups[group.name] = helpers.take_off_intersection_from_array(@top_10_beneficiary_groups.pluck(:name), group.beneficiary_subcategories.map(&:name))
    end
  end
end
