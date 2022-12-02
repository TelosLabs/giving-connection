class CircularIcon::Component < ViewComponent::Base
  def initialize(svg_name:, wrapper_options: {}, svg_options: {})
    @svg_name = svg_name
    @wrapper_options = wrapper_options
    @svg_options = svg_options
  end

  def wrapper_options
    {
      class: "grid place-items-center rounded-full mb-2"
    }.merge(@wrapper_options) { |duplicate_key, existing_value, new_value| "#{existing_value} #{new_value}" }
  end
end