class NonprofitCard::Component < ViewComponent::Base
  def initialize(user:, location:)
    @user = user
    @location = location
  end
end
