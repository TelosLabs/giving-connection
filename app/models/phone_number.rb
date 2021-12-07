# frozen_string_literal: true

class PhoneNumber < ApplicationRecord
  belongs_to :location
end
