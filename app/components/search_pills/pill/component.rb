require "securerandom"

class SearchPills::Pill::Component < ViewComponent::Base
  def initialize(form:, record_attr:, checked:, value:)
    @form = form
    @record_attr = record_attr
    @checked = checked
    @value = value
    @checkbox_id = SecureRandom.alphanumeric
  end
end