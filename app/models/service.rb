# frozen_string_literal: true

class Service < ApplicationRecord
  belongs_to :organization, optional: true
  validates :name, presence: true
end
