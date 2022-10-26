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
    arr = Organization.all.map(&:beneficiary_subcategories).flatten.tally.sort_by { |_beneficiary_subcategory, count| count }.reverse.first(10)
    arr.map { |beneficiary_subcategory, _count| beneficiary_subcategory }
  end
end
