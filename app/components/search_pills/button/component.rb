require "securerandom"

class SearchPills::Button::Component < ApplicationViewComponent
  def initialize(name:, value:, checked:, copy:, options: {})
    @name = name
    @value = value
    @checked = checked
    @copy = copy
    @options = options.merge(
      {
        class: "hidden pill",
        id: SecureRandom.alphanumeric,
        data: {
          search_target: "pill",
          action: "change->search#submitForm change->search#toggleDistanceFilter"
        }
      }
    )
  end
end
