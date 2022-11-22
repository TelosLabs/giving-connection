class NonprofitCard::ImagesCarousel::Component < ViewComponent::Base
  def initialize(images:, image_styles: "", carousel_wrapper_options: {}, slides_window_options: {})
    @images = images
    @carousel_wrapper_options = carousel_wrapper_options
    @slides_window_options = slides_window_options
    @image_styles = image_styles
  end

  def carousel_wrapper_options
    {
      class: "relative",
      # don't override these
      id: "carousel",
      data: {
        carousel: "static"
      }
    }.merge(@carousel_wrapper_options) { |duplicate_key, existing_value, new_value| "#{existing_value} #{new_value}" }
  end

  def slides_window_options
    {
      class: "relative bg-gray-5 overflow-hidden"
    }.merge(@slides_window_options) { |duplicate_key, existing_value, new_value| "#{existing_value} #{new_value}" }
  end
end
