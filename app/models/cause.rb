# frozen_string_literal: true

class Cause < ApplicationRecord
  has_many :services
end
