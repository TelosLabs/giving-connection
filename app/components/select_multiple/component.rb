# frozen_string_literal: true

module SelectMultiple
  class Component < ViewComponent::Base
    def initialize(name:, items: {}, selected: [], options: {}, placeholder: "", required: false)
      @name = name
      @items = items
      @selected = selected
      @options = options
      @placeholder = placeholder
      @required = required
    end

    def options
      {
        class: 'relative flex flex-wrap w-full mt-1 text-base border cursor-text min-h-46px rounded-6px text-gray-3',
        data: {
          controller: 'select-multiple extend-dropdown',
          action: 'click->select-multiple#focus click->extend-dropdown#show click@window->extend-dropdown#hide selectmultiple:clear->select-multiple#clearAll',
          'search-target': 'customInput',
          form_validation_target: "selectMultiple",
          'select-multiple-target': 'container',
          'extend-dropdown-target': 'button',
          'select-multiple-selected-value': @selected,
        },
      }
    end
  end
end
