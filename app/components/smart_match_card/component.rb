class SmartMatchCard::Component < ApplicationViewComponent
  include LocationsHelper

  def initialize(user:, location:)
    @user = user
    @location = location
  end
end
