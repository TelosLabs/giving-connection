class SmartMatchCard::ImagesCarousel::Component < ApplicationViewComponent
  def initialize(images:, carousel_container_options: {})
    @images = images
    @carousel_container_options = carousel_container_options
  end
end
