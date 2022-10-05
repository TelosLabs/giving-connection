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

  def self.most_repeated_in_organizations
    beneficiary_subcategories_count = {}
    Organization.all.each do |organization|
      organization.beneficiary_subcategories.each do |beneficiary_subcategory|
        beneficiary_subcategories_count[beneficiary_subcategory] = beneficiary_subcategories_count[beneficiary_subcategory].to_i + 1
      end
    end
    arr = beneficiary_subcategories_count.sort_by { |beneficiary_subcategory, count| count }.reverse.first(10)
    arr.map { |beneficiary_subcategory, count| beneficiary_subcategory }
  end
end
