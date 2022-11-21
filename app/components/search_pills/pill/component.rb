require "securerandom"

class SearchPills::Pill::Component < ViewComponent::Base
  def initialize(name:, value: , checked:,  options: {})
    @name = name
    @value = value
    @checked = checked
    @options = options.merge(
      {
        class: 'hidden pill',
        id: SecureRandom.alphanumeric
      }
    )
    add_actions(' change->places#hidePopup change->search#updateFiltersState change->search#submitForm')
  end

  private

  def add_actions(actions)
    @options[:data] ||= {}
    @options[:data][:action] ||= ''
    @options[:data][:action] += actions
  end
end
