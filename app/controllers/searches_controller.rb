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

    if @search.results.any?
      puts @search.errors.full_messages
    end
  end

  def create_params
    params.require(:search).permit(:distance, :city, :state, :beneficiary_groups,
                                   :services, :open_now, :open_weekends, :keyword, :zipcode)
  end

  def verify_search_params
    @params_applied = params.dig('search', 'services').present? ||
                      params.dig('search', 'beneficiary_groups').present? ||
                      params.dig('search', 'city').present? ||
                      params.dig('search', 'zipcode').present? ||
                      params.dig('search', 'distance').present? ||
                      params.dig('search', 'open_now').present? ||
                      params.dig('search', 'open_weekends').present?
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
