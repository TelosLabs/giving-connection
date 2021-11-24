# frozen_string_literal: true

class LocationsController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @locations = Location.find(params[:ids]) if params[:ids].present?
    @locations ||= Location.all
    @locations = policy_scope(Location)
  end

  def new
    @location = Location.new
  end

  def create
    org = Organization.new(
      name: Faker::Company.name,
      ein_number: rand(0..1000),
      irs_ntee_code: %w[A00 A90 A26 A91 A02 Q21].sample,
      website: 'org@example.com',
      scope_of_work: %w[International National Regional].sample,
      mission_statement_en: Faker::Company.catch_phrase,
      vision_statement_en: Faker::Company.catch_phrase,
      tagline_en: Faker::Company.catch_phrase,
      description_en: Faker::Company.catch_phrase
    )
    org.creator = current_user
    org.save
    location = org.locations.build(create_params)
    if location.save
      redirect_to root_path
    else
      puts "Loc creation failed: #{location.errors.full_messages.to_sentence}"
    end
  end

  private

  def create_params
    params.require(:location).permit(:address, :longitude, :latitude)
  end
end
