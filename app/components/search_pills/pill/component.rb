require "securerandom"

class SearchPills::Pill::Component < ViewComponent::Base
  def initialize(name:, value: , checked:,  options: {})
    @name = name
    @value = value
    @checked = checked
    @options = options.merge(
      {
        class: 'hidden pill',
        id: SecureRandom.alphanumeric,
        data: {
          action: "change->places#hidePopup change->search#updateFiltersState change->search#submitForm #{options[:data] ? options[:data][:action] : ''}",
          checkbox_select_all_target: options[:data] ? options[:data][:checkbox_select_all_target] : ''
        }
      }
    )
  end
end
