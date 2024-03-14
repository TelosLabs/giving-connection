require "securerandom"

class SearchPills::Pill::Component < ApplicationViewComponent
  def initialize(name:, value:, checked:, options: {data: {action: ''}})
    @name = name
    @value = value
    @checked = checked
    @options = options.merge(
      {
        class: 'hidden pill',
        id: SecureRandom.alphanumeric,
        data: {
          search_target: "pill",
          action: "change->places#hidePopup change->search#updateFiltersState change->search#submitForm"
        }
      }
    )
  end
end
