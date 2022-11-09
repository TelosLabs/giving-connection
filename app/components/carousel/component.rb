
class Carousel::Component < ViewComponent::Base
  def initialize(location:, options: 'relative h-40 w-64 md:w-96 md:h-80 overflow-hidden rounded-lg')
    @location = location
    @options = options
  end
end
