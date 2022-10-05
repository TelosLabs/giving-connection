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
    return 'servicesPill' if @name.include?('services')
    return 'causesPill' if @name.include?('causes')
    return 'beneficiaryGroupsPill' if @name.include?('beneficiary_groups')
  end
end
