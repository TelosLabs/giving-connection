# frozen_string_literal: true

class Service < ApplicationRecord
  belongs_to :location, optional: true
  validates :name, presence: true
end
