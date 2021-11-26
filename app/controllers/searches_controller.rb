# frozen_string_literal: true

class SearchesController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    @search = Search.new
    @causes_and_services = {}
    Cause.all.each do |cause|
      @causes_and_services[cause.name] = cause.services.map(&:name)
    end
    @beneficiary_groups = {}
    BeneficiaryGroup.all.each do |group|
      @beneficiary_groups[group.name] = group.beneficiary_subcategories.map(&:name)
    end
    @results = Location.all
  end

  def create
    @search = Search.new(create_params)

    if @search.save && @search.results.any?
      @results = @search.results
      render :new
    else
      render :new
      puts @search.errors.full_messages
    end
  end

  def create_params
    params.require(:search).permit(:distance, :city, :state, :beneficiary_groups,
                                   :services, :open_now, :open_weekends, :keyword, :zipcode)
  end
end
