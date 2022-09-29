require "securerandom"

class SearchPills::Pill::Component < ViewComponent::Base
  def initialize(form:, record_attr:, options: {}, value:)
    @form = form
    @record_attr = record_attr
    @options = options.merge(
      {
        class: "hidden pill",
        id: SecureRandom.alphanumeric,
        onchange: "this.form.requestSubmit()",
        data: {
          action: "change->search#updatePillsCounter"
        }
      }
    )
    # raise if record_attr == :services
    @value = value
  end
end
