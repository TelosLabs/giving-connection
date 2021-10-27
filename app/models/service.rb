# frozen_string_literal: true

class Service < ApplicationRecord
  belongs_to :organization
  validates :name, presence: true
end
