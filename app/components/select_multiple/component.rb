# frozen_string_literal: true

module SelectMultiple
  class Component < ApplicationViewComponent
    def initialize(f: "", klass: "", name: "", items: {}, selected: [], options: {}, placeholder: "", required: false, stimulus_controller: nil)
      @f = f
      @klass = klass
      @name = name
      @items = items
      @selected = selected
      @options = options
      @placeholder = placeholder
      @required = required
      @stimulus_controller = stimulus_controller || "select-multiple--component"
    end

    def options
      {
        class: "relative flex flex-wrap w-full mt-1 text-base border cursor-text min-h-46px rounded-6px text-gray-3",
        data: {
          controller: "#{@stimulus_controller} extend-dropdown",
          action: "click->#{@stimulus_controller}#focus click->extend-dropdown#show click@window->extend-dropdown#hide selectmultiple:clear->#{controller}#clearAll",
          "search-target": "customInput",
          form_validation_target: "selectMultiple",
          "#{@stimulus_controller}-target": "container",
          "extend-dropdown-target": "button",
          "#{@stimulus_controller}-selected-value": @selected
        }
      }.merge(@options) do |key, first_value, repeated_value|
        if key == :data
          first_value.merge(repeated_value) { |_, old_value, new_value| "#{new_value} #{old_value}" }
        elsif key == :class
          "#{new_value} #{old_value}"
        end
      end
    end

    def format_cause_name(name)
      name.downcase
        .delete("&")
        .split(" ")
        .join("_")
        .tr("-", "_") <<
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
