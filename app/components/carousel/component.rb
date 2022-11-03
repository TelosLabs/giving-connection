
class Carousel::Component < ViewComponent::Base
  def initialize(location:, design_class: nil)
    @location = location
    @class = design_class || 'relative h-72 w-64 md:w-96 md:h-80 overflow-hidden rounded-lg'
  end
end
