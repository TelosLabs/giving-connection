# frozen_string_literal: true
class SearchBar::Component < ViewComponent::Base
  def initialize(form:, search:)
    @form = form
    @search = search
  end

  def options
    {
      class: '',
      type: ''
    }
  end
end
