# frozen_string_literal: true
require 'locations_helper'

module SearchBar
  class Component < ViewComponent::Base
    include LocationsHelper
    def initialize(form:, search:)
      @form = form
      @search = search
      @location = get_ip_location.map { | l | ["#{l[:city]}, #{l[:state]}", {value: l[:city], latitude: l[:latitude], longitude: l[:longitude]} ] }
    end

    def options
      {
        class: '',
        type: ''
      }
    end
  end
end
