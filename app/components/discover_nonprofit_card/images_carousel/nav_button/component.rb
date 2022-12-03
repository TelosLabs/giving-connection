class DiscoverNonprofitCard::ImagesCarousel::NavButton::Component < ViewComponent::Base
  def initialize(position: , direction:, outline:)
    @position = position
    @direction = direction
    @outline = outline
  end

  def button_options
    {
      type: "button",
      class: "swiper-button-#{@direction} group absolute #{@position} -translate-y-1/2 cursor-pointer no-pseudo-elems"
    }
  end
end
