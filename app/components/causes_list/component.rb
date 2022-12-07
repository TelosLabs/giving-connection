class CausesList::Component < ViewComponent::Base
  def initialize(causes:, navigational: false, list_options: {}, cause_options: {}, icon_wrapper_options: {})
    @causes = causes
    # true if we want to use links
    @navigational = navigational
    @list_options = list_options
    @cause_options = cause_options
    @icon_wrapper_options = icon_wrapper_options
  end

  def cause_options(cause)
    {
      href: @navigational ? discover_show_path(cause) : nil,
      class: "grid place-items-center text-center"
    }.merge(@cause_options) { |duplicate_key, existing_value, new_value| "#{existing_value} #{new_value}" }
  end

  def icon_wrapper_options
    {
      class: "grid place-items-center rounded-full mb-2 bg-blue-pale"
    }.merge(@icon_wrapper_options) { |duplicate_key, existing_value, new_value| "#{existing_value} #{new_value}" }
  end

  def tag
    @navigational ? :a : :span
  end
end
