# frozen_string_literal: true

class LocationService < ApplicationRecord
  belongs_to :location
  belongs_to :service
end
