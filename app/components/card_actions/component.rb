class CardActions::Component < ViewComponent::Base
  def initialize(current_user:, result:)
    @current_user = current_user
    @result = result
  end
end
