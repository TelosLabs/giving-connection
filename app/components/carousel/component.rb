# frozen_string_literal: true

# carousel view component
# rubocop:disable Style/ClassAndModuleChildren
# rubocop:disable Lint/MissingSuper
class Carousel::Component < ViewComponent::Base
  def initialize(location:, options: {})
    @location = location
    @options = "swiper-container overflow-hidden rounded-lg my-3 shadow-2xl #{options[:size]}"
  end
end

# rubocop:enable Style/ClassAndModuleChildren
# rubocop:enable Lint/MissingSuper
