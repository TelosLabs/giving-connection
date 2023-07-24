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
          action: "change->search#updateFiltersState change->search#submitForm",
        }
      }
    )
  end
end
