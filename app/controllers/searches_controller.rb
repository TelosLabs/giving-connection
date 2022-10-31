# frozen_string_literal: true

class SearchesController < ApplicationController
  skip_before_action :authenticate_user!
  before_action only: [:show] do
    set_causes
    set_services
    set_beneficiary_groups
  end

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

  private

  def set_causes
    @top_10_causes = Cause.top_(limit: 10)
    @causes = Cause.all.pluck(:name) - @top_10_causes.pluck(:name)
  end

  def set_services
    @services = {}
    @top_10_services = Service.top_(limit: 10)
    Cause.all.each do |cause|
      @services[cause.name] = cause.services.map(&:name) - @top_10_services.pluck(:name)
    end
  end

  def set_beneficiary_groups
    @beneficiary_groups = {}
    @top_10_beneficiary_subcategories = BeneficiarySubcategory.top_(limit: 10)
    BeneficiaryGroup.all.each do |group|
      @beneficiary_groups[group.name] = group.beneficiary_subcategories.map(&:name) - @top_10_beneficiary_subcategories.pluck(:name)
    end
  end
end
