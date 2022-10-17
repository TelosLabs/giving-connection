
class Carousel::Component < ViewComponent::Base
  def initialize(location:, design_class: nil)
    @location = location
    @class = design_class
  end
end
