# frozen_string_literal: true

class BeneficiarySubcategory < ApplicationRecord
  belongs_to :beneficiary_group
end
