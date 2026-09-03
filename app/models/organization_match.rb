# frozen_string_literal: true

class OrganizationMatch < ApplicationRecord
  belongs_to :quiz_submission
  belongs_to :organization

  validates :score, presence: true
  validates :rank, presence: true
end
