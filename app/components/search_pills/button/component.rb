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
        data: {
<<<<<<< HEAD
          action: "change->search#updatePillsCounter change->search#updateFiltersState change->search#submitForm",
=======
          action: "change->search#updateFiltersState"
>>>>>>> 534e2122080edcb532862d450278286636ca1514
        }
      }
    )
  end
end
