class Causes::Component < ViewComponent::Base
  def initialize(causes:, list_options:, cause_options:, icon_options:)
    @causes = causes
    @list_options = list_options
    @cause_options = cause_options
    @icon_options = icon_options
  end

  def cause_options
    {
      class: "inline-flex flex-col items-center text-center font-medium"
    }.merge(@cause_options) { |duplicate_key, existing_value, new_value| "#{existing_value} #{new_value}" }
  end

  def icon_options
    {
      class: "grid place-items-center rounded-full mb-2 bg-blue-pale",
      aria_hidden: true
    }.merge(@icon_options) { |duplicate_key, existing_value, new_value| "#{existing_value} #{new_value}" }
  end
end
