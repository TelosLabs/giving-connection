class CausesList::Component < ApplicationViewComponent
  include InlineSvg::ActionView::Helpers

  def initialize(causes:, tooltip: false, list_options: {}, cause_options: {}, icon_wrapper_options: {}, tooltip_options: {}, icon_svg_options: {})
    @causes = causes
    @list_options = list_options
    @cause_options = cause_options
    @icon_wrapper_options = icon_wrapper_options
    @icon_svg_options = icon_svg_options
    @tooltip = tooltip
    @tooltip_options = tooltip_options
    @tooltip_id = SecureRandom.hex
  end

  def link_url(cause)
    discover_show_url(cause)
  end

  def cause_options
    {
      class: @tooltip ? "relative" : "grid place-items-center text-center"
    }.merge(@cause_options) { |_duplicate_key, existing_value, new_value| "#{existing_value} #{new_value}" }
  end

  def icon_wrapper_options
    {
      class: "grid place-items-center rounded-full mb-2 bg-blue-pale"
    }.merge(@icon_wrapper_options) { |_duplicate_key, existing_value, new_value| "#{existing_value} #{new_value}" }
  end

  def icon_svg_options
    {
      class: ""
    }.merge(@icon_svg_options) { |_duplicate_key, existing_value, new_value| "#{existing_value} #{new_value}" }
  end

  def tooltip_options
    {
      class: @tooltip ? "absolute hidden" : "",
      role: @tooltip ? "tooltip" : "",
      id: @tooltip ? @tooltip_id : ""
    }.merge(@tooltip_options) { |_duplicate_key, existing_value, new_value| "#{existing_value} #{new_value}" }
  end
end
