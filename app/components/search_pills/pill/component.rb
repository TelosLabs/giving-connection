require "securerandom"

class SearchPills::Pill::Component < ViewComponent::Base
  def initialize(form:, record_attr:, options: {}, value:)
    @form = form
    @record_attr = record_attr
    @options = options.merge(
      {
        class: 'hidden pill',
        id: SecureRandom.alphanumeric,
        onchange: 'this.form.requestSubmit()',
        data: {
          action: 'change->search#updatePillsCounter',
          'search-target': set_target
        }
      }
    )
    # raise if record_attr == :services
    @value = value
  end

  def set_target
    case @record_attr
    when :services
      "servicesPill"
    when :causes
      "causesPill"
    when :beneficiary_groups
      "beneficiaryGroupsPill"
    end
  end
end
