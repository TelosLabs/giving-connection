require 'securerandom'

class Tooltip::Component < ViewComponent::Base
  def initialize(copy:, tooltip_options: {}, wrapper_options: {})
    @copy = copy
    @tooltip_options = tooltip_options
    @wrapper_options = wrapper_options
    @tooltip_id = SecureRandom.hex
  end

  def tooltip_options
    {
      class: "absolute hidden",
      role: "tooltip",
      id: @tooltip_id
    }.merge(@tooltip_options) { |duplucate_key, existing_value, new_value| "#{existing_value} #{new_value}" }
  end

  def wrapper_options
    {
      class: "relative"
    }.merge(@wrapper_options) { |duplucate_key, existing_value, new_value| "#{existing_value} #{new_value}" }
  end
end
