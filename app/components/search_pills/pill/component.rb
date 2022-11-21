require "securerandom"

class SearchPills::Pill::Component < ViewComponent::Base
  def initialize(name:, value: , checked:,  options: {})
    options = build_options(options) if options[:data].present?
    @name = name
    @value = value
    @checked = checked
    @options = {
      class: 'hidden pill',
      id: SecureRandom.alphanumeric,
      data: {
        multiple: options[:multiple],
        checkbox_select_all_target: options[:checkbox_select_all_target],
        action: "#{options[:action]} change->places#hidePopup change->search#updateFiltersState change->search#submitForm"
      }
    }
  end

  private

  def build_options(options)
    hash = {}
    hash[:action] = options[:data][:action] || ''
    hash[:multiple] = options[:data][:multiple] || ''
    hash[:checkbox_select_all_target] = options[:data][:checkbox_select_all_target] || ''
    hash
  end
end
