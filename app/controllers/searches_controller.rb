# frozen_string_literal: true

class SearchesController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_causes_and_services, only: [:show]
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
    input_services = params.require(:search)[:services].try(:permit!)
    input_groups = params.require(:search)[:beneficiary_groups].try(:permit!)
    params.require(:search).permit(:distance, :city, :state, :lat, :lon,
                                   :open_now, :open_weekends, :keyword, :zipcode).merge(
                                     services: input_services,
                                     beneficiary_groups: input_groups
                                   )
  end

  def verify_search_params
    @params_applied = params.dig('search', 'services').present? ||
                      params.dig('search', 'beneficiary_groups').present? ||
                      params.dig('search', 'city').present? ||
                      params.dig('search', 'zipcode').present? ||
                      params.dig('search', 'distance').present? ||
                      params.dig('search', 'open_now').present?
  end

  private

  def set_causes_and_services
    @causes_and_services = {}
    Cause.all.each do |cause|
      @causes_and_services[cause.name] = cause.services.map(&:name)
    end
  end

  def set_beneficiary_groups
    @beneficiary_groups = {}
    BeneficiaryGroup.all.each do |group|
      @beneficiary_groups[group.name] = group.beneficiary_subcategories.map(&:name)
    end
  end
end
