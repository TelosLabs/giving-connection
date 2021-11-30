# frozen_string_literal: true

# == Schema Information
#
# Table name: beneficiary_subcategories
#
#  id                   :bigint           not null, primary key
#  name                 :string
#  beneficiary_group_id :bigint           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class BeneficiarySubcategory < ApplicationRecord
  belongs_to :beneficiary_group
end
