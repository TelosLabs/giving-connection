class DiscoverNonprofitCard::ImagesCarousel::NavButton::Component < ApplicationViewComponent
  def initialize(direction:, outline:)
    @direction = direction
    @outline = outline
  end

  def button_options
    {
      type: "button",
      class: "swiper-button-#{@direction} group absolute -translate-y-1/2 cursor-pointer no-pseudo-elems"
    }
  end
end
