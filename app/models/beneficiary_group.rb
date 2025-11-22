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
end
