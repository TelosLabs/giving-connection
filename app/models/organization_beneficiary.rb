# frozen_string_literal: true

# == Schema Information
#
# Table name: organization_beneficiaries
#
#  id                         :bigint           not null, primary key
#  organization_id            :bigint           not null
#  beneficiary_subcategory_id :bigint           not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
class OrganizationBeneficiary < ApplicationRecord
  belongs_to :organization
  belongs_to :beneficiary_subcategory
end
