# frozen_string_literal: true

class PhoneNumber < ApplicationRecord
  belongs_to :contact_information
end
