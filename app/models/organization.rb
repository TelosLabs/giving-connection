# == Schema Information
#
# Table name: organizations
#
#  id                   :bigint           not null, primary key
#  name                 :string           not null
#  ein_number           :string           not null
#  irs_ntee_code        :string           not null
#  website              :string
#  scope_of_work        :string           not null
#  creator_type         :string
#  creator_id           :bigint
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  mission_statement_en :text             not null
#  mission_statement_es :text
#  vision_statement_en  :text             not null
#  vision_statement_es  :text
#  tagline_en           :text             not null
#  tagline_es           :text
#  description_en       :text             not null
#  description_es       :text
#
class Organization < ApplicationRecord
  include OrganizationConstants

  has_many :locations
  belongs_to :creator, polymorphic: true

  validates :name, presence: true, uniqueness: true
  validates :ein_number, presence: true, uniqueness: true
  validates :irs_ntee_code, presence: true, inclusion: { in: OrganizationConstants::NTEE_CODE }
  validates :mission_statement_en, presence: true
  validates :vision_statement_en, presence: true
  validates :tagline_en, presence: true
  validates :description_en, presence: true
  validates :scope_of_work, presence: true, inclusion: { in: OrganizationConstants::SCOPE }
end
