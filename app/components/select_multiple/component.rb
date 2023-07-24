# frozen_string_literal: true
module SelectMultiple
  class Component < ApplicationViewComponent
    def initialize(f: "", klass: "", name: "", items: {}, selected: [], options: {}, placeholder: "", required: false)
      @f = f
      @klass = klass
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

    def format_cause_name(name)
      name.downcase.
          delete("&").
          split(" ").
          join("_").
          gsub("-", "_") <<
          ".svg"
    end

    def collection(name)
      case @klass
      when "Beneficiary"
        BeneficiaryGroup.find_by(name: name).beneficiary_subcategories
      when "Service"
        Cause.find_by(name: name).services
      end
    end

    def ids_array
      case @klass
      when "Beneficiary"
        :beneficiary_subcategory_ids
      when "Service"
        :service_ids
      end
    end
  end
end
