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
          search_target: "radioButton",
          action: "change->search#submitForm click->search#toggleDistanceFilter"
        }
      }
    )
  end
end
