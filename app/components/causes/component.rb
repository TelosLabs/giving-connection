class Causes::Component < ViewComponent::Base
  def initialize(causes:)
    @causes = causes
  end
end
