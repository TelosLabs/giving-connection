class Organization < ApplicationRecord
  include OrganizationConstants

  belongs_to :creator , polymorphic: true
  has_one :social_media, dependent: :destroy
  accepts_nested_attributes_for :social_media
  
  validates :name, presence: true, uniqueness: true
  validates :ein_number, presence: true, uniqueness: true
  validates :irs_ntee_code, presence: true, inclusion: { in: OrganizationConstants::NTEE_CODE }
  validates :mission_statement_en, presence: true
  validates :vision_statement_en, presence: true
  validates :tagline_en, presence: true
  validates :description_en, presence: true
  validates :scope_of_work, presence: true, inclusion: { in: OrganizationConstants::SCOPE }

end

