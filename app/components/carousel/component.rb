# frozen_string_literal: true

class Carousel::Component < ViewComponent::Base
  def initialize(location:, options: {})
    @location = location
    @options = "swiper-container overflow-hidden rounded-lg my-3 shadow-2xl #{options[:class]}"
  end
end
