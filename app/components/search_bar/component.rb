module SearchBar
  class Component < ApplicationViewComponent
    def initialize(form:, search:, current_location:, locations:)
      @form = form
      @search = search
      @current_location = current_location
      @locations = locations
    end

    def options
      {
        class: "",
        type: ""
      }
    end
  end
end
