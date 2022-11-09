# frozen_string_literal: true

# carousel view component
# rubocop:disable Style/ClassAndModuleChildren
# rubocop:disable Lint/MissingSuper
class Carousel::Component < ViewComponent::Base
  def initialize(location:, options: 'swiper-container h-40 w-64 md:w-96 md:h-80 overflow-hidden rounded-lg my-3 shadow-lg')
    @location = location
    @options = options
  end
end

# rubocop:enable Style/ClassAndModuleChildren
# rubocop:enable Lint/MissingSuper
