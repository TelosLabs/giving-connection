# frozen_string_literal: true

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

  has_many :tags, dependent: :destroy
  has_many :organization_categories, dependent: :destroy
  has_many :categories, through: :organization_categories
  has_many :organization_beneficiaries, dependent: :destroy
  has_one :organization_admin, dependent: :destroy
  has_many :beneficiary_subcategories, through: :organization_beneficiaries
  has_many :locations, dependent: :destroy
  has_many :additional_locations, -> { where(main: false) }, class_name: 'Location', foreign_key: :organization_id
  has_one :main_location, -> { where(main: true) }, class_name: 'Location', foreign_key: :organization_id
  has_one :social_media, dependent: :destroy
  has_one_attached :logo
  has_one_attached :cover_photo
  belongs_to :creator, polymorphic: true

  validates :name, presence: true, uniqueness: true
  validates :ein_number, presence: true, uniqueness: true
  validates :irs_ntee_code, presence: true, inclusion: { in: OrganizationConstants::NTEE_CODE }
  validates :mission_statement_en, presence: true
  validates :vision_statement_en, presence: true
  validates :tagline_en, presence: true
  validates :description_en, presence: true
  validates :scope_of_work, presence: true, inclusion: { in: OrganizationConstants::SCOPE }
  validates :logo, content_type: ['image/png', 'image/jpg', 'image/jpeg'],
                   size: { less_than: 5.megabytes, message: 'File too large. Must be less than 5MB in size' }

  after_create :attach_logo_and_cover

  accepts_nested_attributes_for :organization_beneficiaries, allow_destroy: true
  accepts_nested_attributes_for :social_media, allow_destroy: true
  accepts_nested_attributes_for :additional_locations, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :locations

  private

  def attach_logo_and_cover
    cover_photo.attach(io: File.open('app/assets/images/cover-default.png'), filename: 'cover-default.png')
    file_logo = "logo-default#{rand(1..6)}"
    filepath = File.open("app/assets/images/#{file_logo}.png")
    logo.attach(io: filepath, filename: "#{file_logo}.png") unless logo.attached?
  end
end
