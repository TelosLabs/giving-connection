# frozen_string_literal: true

class ContactInformation < ApplicationRecord
  belongs_to :organization

  has_many :phone_numbers
  accepts_nested_attributes_for :phone_numbers
end
