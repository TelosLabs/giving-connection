# frozen_string_literal: true

class SearchesController < ApplicationController
  def new
    @search = Search.new
    @causes_and_services = {}
    Cause.all.each do |cause|
      @causes_and_services[cause.name] = cause.services.map { |s| s.name }
    end
    @beneficiary_groups = {}
    BeneficiaryGroup.all.each do |group|
      @beneficiary_groups[group.name] = group.beneficiary_subcategories.map { |category| category.name }
    end
  end

  def create
    search = Search.new(create_params)
    if search.search && search.results.any?
      @results = search.results
      redirect_to locations_path(ids: @results.ids)
    else
      puts 'didnt work'
    end
  end

  def keyword_params
    params.permit(:keyword)
  end

  def create_params
    params.permit(:distance, :city, :state, :beneficiary_groups,
                  :services, :open_now, :open_weekends, :keyword)
  end
end
