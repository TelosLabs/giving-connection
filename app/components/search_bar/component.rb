# frozen_string_literal: true
class SearchBar::Component < ApplicationViewComponent

  option :form, default: -> { }
  option :search, default: -> { }
  option :current_location, default: -> { }

  def options
    {
      class: '',
      type: ''
    }
  end

  def location_full_city
    [
      @current_location.dig(:city),
      @current_location.dig(:state),
      @current_location.dig(:country) || "EE. UU."
    ].join(', ') if @current_location.dig(:city).present? and @current_location.dig(:state).present?
  end
end
