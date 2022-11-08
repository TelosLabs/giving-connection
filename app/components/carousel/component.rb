
class Carousel::Component < ViewComponent::Base
  def initialize(location:, options: {})
    @location = location
    @options = options || 'relative h-72 w-64 md:w-96 md:h-80 overflow-hidden rounded-lg'
  end
end
