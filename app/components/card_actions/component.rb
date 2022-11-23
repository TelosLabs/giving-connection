class CardActions::Component < ViewComponent::Base
  include ApplicationHelper

  def initialize(current_user:, result:)
    @current_user = current_user
    @result = result
    @website = @result&.decorate&.website || @result&.organization&.decorate&.website
  end
end
