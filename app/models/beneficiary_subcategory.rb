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
  include PgSearch::Model
  multisearchable against: :name

  belongs_to :beneficiary_group

  # Adding/renaming a subcategory changes the cached groups-to-subcategories hash even though
  # the BeneficiaryGroup record itself didn't change.
  after_commit -> { Rails.cache.delete_multi(%w[search_pills/beneficiary_groups select_multiple/beneficiary_groups_with_subcategories]) }

  def self.top(limit: 10)
    find(top_organization_subcategories_ids(limit: limit))
  end

  def self.top_organization_subcategories_ids(limit: 10)
    OrganizationBeneficiary.group(:beneficiary_subcategory_id).order("count(beneficiary_subcategory_id) desc").limit(limit).count.keys
  end
end
