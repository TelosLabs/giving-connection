# frozen_string_literal: true
class SelectMultiple::Component < ViewComponent::Base
  def initialize(name:, items: {}, selected: [])
    @name = name
    @items = items
    @selected = selected
    # TODO: allow options to be passed in
  end

  def options
    {
      class: 'relative flex flex-wrap w-full mt-1 text-base border cursor-text min-h-46px rounded-6px text-gray-3',
      data: {
        controller: 'select-multiple dropdown',
        action: 'click->select-multiple#focus click->dropdown#show click@window->dropdown#hide selectmultiple:clear->select-multiple#clearAll',
        'search-target': 'customInput',
        'select-multiple-target': 'container',
        'dropdown-target': 'button',
        'select-multiple-selected-value': @selected
      }
    }
  end
end
