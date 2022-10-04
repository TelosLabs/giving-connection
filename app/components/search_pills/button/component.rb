require "securerandom"

class SearchPills::Button::Component < ViewComponent::Base
  def initialize(name:, value:, checked:, copy:)
    @name = name
    @value = value
    @checked = checked
    @copy = copy
    @radio_id = SecureRandom.alphanumeric
  end
end