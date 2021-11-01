# frozen_string_literal: true

class BeneficiaryGroup < ApplicationRecord
  has_many :beneficiary_subcategories, dependent: :destroy
end
