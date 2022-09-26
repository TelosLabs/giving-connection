require "securerandom"

class SearchPills::Button::Component < ViewComponent::Base
  def initialize(form:, record_attr:, value:, checked:, copy:)
    @form = form
    @record_attr = record_attr
    @value = value
    @checked = checked
    @copy = copy
    @radio_id = SecureRandom.alphanumeric
  end
end