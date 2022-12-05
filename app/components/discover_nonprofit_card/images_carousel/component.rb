class DiscoverNonprofitCard::ImagesCarousel::Component < ViewComponent::Base
  def initialize(images:, image_styles: "",  placeholder_options: {}, carousel_container_options: {})
    @images = images
    @image_styles = image_styles
    @placeholder_options = placeholder_options
    @carousel_container_options = carousel_container_options
  end

  def carousel_container_options
    {
      class: "swiper-container",
      # don't override these
      data: {
        controller: "carousel",
        carousel_options_value: '{"navigation": {"nextEl": ".swiper-button-next", "prevEl": ".swiper-button-prev"}}'
      }
    }.merge(@carousel_container_options) { |_duplicate_key, existing_value, new_value| "#{existing_value} #{new_value}" }
  end

  def placeholder_options
    {
      class: ""
    }.merge(@placeholder_options) { |_duplicate_key, existing_value, new_value| "#{existing_value} #{new_value}" }
  end
end
