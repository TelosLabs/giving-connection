module SearchBar
  class Component < ApplicationViewComponent
    def initialize(form:, search:, current_location:)
      @form = form
      @search = search
      @current_location = current_location
    end

    def options
      {
        class: "",
        type: ""
      }
    end
  end
end
