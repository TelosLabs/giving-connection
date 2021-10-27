# frozen_string_literal: true

class OrganizationBeneficiary < ApplicationRecord
  belongs_to :organization
  belongs_to :beneficiary_subcategory
end
