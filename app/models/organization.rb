# frozen_string_literal: true

class Organization < ApplicationRecord
  include OrganizationConstants

  after_create :attach_logo_and_cover

  belongs_to :creator, polymorphic: true
  has_one :social_media, dependent: :destroy
  accepts_nested_attributes_for :social_media

  has_many :subcategories
  has_one :category, through: :subcategories

  has_one_attached :logo
  has_one_attached :cover_photo

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

  private

  def attach_logo_and_cover
    cover_photo.attach(io: File.open('app/assets/images/cover-default.png'), filename: 'cover-default.png')
    unless logo.attached?
      logo = "logo-default#{rand(1..6)}"
      self.logo.attach(io: File.open("app/assets/images/#{logo}.png"), filename: "#{logo}.png")
    end
  end
end
