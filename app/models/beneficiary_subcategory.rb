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

  def self.top_10_beneficiary_groups
    Organization.joins(:beneficiary_subcategories).group(:beneficiary_subcategory_id).order('count(beneficiary_subcategory_id) desc').limit(10).pluck(:beneficiary_subcategory_id).map { |id| BeneficiarySubcategory.find(id) }
  end
end
