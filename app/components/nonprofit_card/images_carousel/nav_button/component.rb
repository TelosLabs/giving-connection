class NonprofitCard::ImagesCarousel::NavButton::Component < ViewComponent::Base
  def initialize(position: , direction:, outline:)
    @position = position
    @direction = direction
    @outline = outline
  end

  def button_options
    {
      type: "button",
      class: "group absolute #{@position} z-30 -translate-y-1/2 cursor-pointer",
      "data-carousel-#{@direction}": ""
    }
  end

  def button_copy
    @direction == :prev ? "previous slide" : "next slide"
  end
end
