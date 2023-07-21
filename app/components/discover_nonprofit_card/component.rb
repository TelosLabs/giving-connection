class DiscoverNonprofitCard::Component < ApplicationViewComponent
  def initialize(user:, location:)
    @user = user
    @location = location
  end
end
