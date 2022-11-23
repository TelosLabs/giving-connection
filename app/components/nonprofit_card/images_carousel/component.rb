class NonprofitCard::ImagesCarousel::Component < ViewComponent::Base
  def initialize(images:, image_styles: "", carousel_container_options: {}, slides_wrapper_options: {})
    @images = images
    @carousel_container_options = carousel_container_options
    @slides_wrapper_options = slides_wrapper_options
    @image_styles = image_styles
  end

  def carousel_container_options
    {
      class: "relative swiper-container bg-gray-5 overflow-hidden",
      # don't override these
      data: {
        controller: "carousel",
        carousel_options_value: '{"navigation": {"nextEl": ".swiper-button-next", "prevEl": ".swiper-button-prev"}}'
      }
    }.merge(@carousel_container_options) { |duplicate_key, existing_value, new_value| "#{existing_value} #{new_value}" }
  end

  def slides_wrapper_options
    {
      class: "swiper-wrapper"
    }.merge(@slides_wrapper_options) { |duplicate_key, existing_value, new_value| "#{existing_value} #{new_value}" }
  end
end
