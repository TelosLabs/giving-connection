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
          action: "click->#{@stimulus_controller}#focus click->extend-dropdown#show click@window->extend-dropdown#hide selectmultiple:clear->#{@stimulus_controller}#clearAll",
          "search-target": "customInput",
          form_validation_target: "selectMultiple",
          "#{@stimulus_controller}-target": "container",
          "extend-dropdown-target": "button"
        }
      }.merge(@options) do |key, first_value, repeated_value|
        if key == :data
          first_value.merge(repeated_value) { |_, old_value, new_value| "#{new_value} #{old_value}" }
        elsif key == :class
          "#{new_value} #{old_value}"
        end
      end
    end

    def checked?(item)
      return false if @stimulus_controller == "select-multiple-search"

      @selected.to_a.include?(item)
    end

    def grouped_items
      keyed_items? ? @items : @items.sort
    end

    def keyed_items?
      @items.is_a?(Hash) && @items.each_value.any?(Hash)
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
        beneficiary_groups_with_subcategories[name] || []
      when "Service"
        causes_with_services[name] || []
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

    private

    def causes_with_services
      Rails.cache.fetch("select_multiple/causes_with_services", expires_in: 1.day) do
        Cause.includes(:services).index_with(&:services).transform_keys(&:name)
      end
    end

    def beneficiary_groups_with_subcategories
      Rails.cache.fetch("select_multiple/beneficiary_groups_with_subcategories", expires_in: 1.day) do
        BeneficiaryGroup.includes(:beneficiary_subcategories).index_with(&:beneficiary_subcategories).transform_keys(&:name)
      end
    end
  end
end
