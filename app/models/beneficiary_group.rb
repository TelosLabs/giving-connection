# frozen_string_literal: true

# == Schema Information
#
# Table name: beneficiary_groups
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class BeneficiaryGroup < ApplicationRecord
  include PgSearch::Model
  multisearchable against: :name
  has_many :beneficiary_subcategories, dependent: :destroy

  # Cached for a day in SearchesController and SelectMultiple::Component;
  # bust it immediately on write instead of leaving up to a day of staleness after an edit.
  after_commit -> { Rails.cache.delete_multi(%w[search_pills/beneficiary_groups select_multiple/beneficiary_groups_with_subcategories]) }
end
