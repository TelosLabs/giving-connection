require "securerandom"

class SearchPills::Button::Component < ViewComponent::Base
  def initialize(name:, value:, checked:, copy:, options: {})
    @name = name
    @value = value
    @checked = checked
    @copy = copy
    @options = options.merge(
      {
        class: "hidden pill",
        id: SecureRandom.alphanumeric,
        onchange: "this.form.requestSubmit()",
        data: {
          action: "change->search#updatePillsCounter change->search#managePillsCounterDisplay"
        }
      }
    )
  end
end