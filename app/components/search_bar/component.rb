# frozen_string_literal: true

# search bar view component
# rubocop:disable Lint/MissingSuper
# rubocop:disable Style/Documentation
module SearchBar
  class Component < ApplicationViewComponent
    def initialize(form:, search:)
      @form = form
      @search = search
    end

    def options
      {
        class: "",
        type: ""
      }
    end
  end
end
# rubocop:enable Lint/MissingSuper
# rubocop:enable Style/Documentation
