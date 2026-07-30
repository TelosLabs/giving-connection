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
#  second_name          :string
#  phone_number         :string
#  email                :string
#
class Organization < ApplicationRecord
  include Organizations::Constants
  validates_with OrganizationValidator
  include PgSearch::Model

  attribute :in_kind_donation_items, :json, default: []

  multisearchable against: [:name]

  scope :active, -> { where(active: true) }

  has_many :tags, dependent: :destroy
  has_many :organization_causes, dependent: :destroy
  has_many :causes, through: :organization_causes
  has_many :organization_beneficiaries, dependent: :destroy
  has_many :organization_admins, dependent: :destroy
  has_many :beneficiary_subcategories, through: :organization_beneficiaries
  has_many :locations, dependent: :destroy
  has_many :additional_locations, -> { where(main: false) }, class_name: "Location", foreign_key: :organization_id
  has_one :main_location, -> { where(main: true) }, class_name: "Location", foreign_key: :organization_id
  has_one :social_media, dependent: :destroy
  has_one_attached :logo
  has_one_attached :cover_photo
  belongs_to :creator, polymorphic: true

  validates :name, presence: true, uniqueness: true
  validates :organization_causes, presence: true
  validates :ein_number, presence: true
  validates :irs_ntee_code, presence: true, inclusion: {in: Organizations::Constants::NTEE_CODE}
  validates :mission_statement_en, presence: true
  validates :scope_of_work, presence: true, inclusion: {in: Organizations::Constants::SCOPE}
  validates :logo, content_type: ["image/png", "image/jpeg"],
    size: {less_than: 5.megabytes, message: "File too large. Must be less than 5MB in size"}

  before_validation :normalize_in_kind_donation_items
  validate :validate_in_kind_donation_items

  after_create :attach_logo_and_cover

  accepts_nested_attributes_for :social_media, allow_destroy: true
  accepts_nested_attributes_for :locations, allow_destroy: true
  accepts_nested_attributes_for :organization_beneficiaries, allow_destroy: true
  accepts_nested_attributes_for :organization_causes, allow_destroy: true

  def self.in_kind_donation_items_options
    Organizations::Constants::IN_KIND_DONATION_ITEMS
  end

  def self.in_kind_donation_item_label(item_key)
    Organizations::Constants::IN_KIND_DONATION_ITEMS[item_key.to_s]
  end

  def regenerate_org_locations_slugs
    locations.order(:created_at).each do |location|
      base_slug = ein_number
      slug = base_slug
      counter = 1

      while Location.exists?(slug: slug)
        slug = "#{base_slug}-#{counter}"
        counter += 1
      end

      location.slug = slug
      location.save!
    end
  end

  # Attaches the default logo/cover for records that don't have them yet.
  # Normally handled by the after_create callback, but bulk inserts via
  # activerecord-import skip callbacks, so the importer calls this directly.
  def ensure_default_media!
    attach_logo_and_cover
  end

  # Image sources for views/components. Returns the attached image when present,
  # otherwise the bundled default asset name. Prevents `image_tag`/`url_for` from
  # crashing with "Can't resolve image into URL: ... for nil" on orgs that never
  # got media attached (bulk-imported/seeded orgs skip the after_create hook).
  # Both an ActiveStorage attachment and an asset-name string are valid
  # `image_tag` arguments, so callers can pass the result straight through.
  def cover_photo_or_default
    cover_photo.attached? ? cover_photo : "cover-default.png"
  end

  def logo_or_default
    logo.attached? ? logo : "logo-default1.png"
  end

  private

  def normalize_in_kind_donation_items
    normalized_items = Array(in_kind_donation_items).compact.map(&:to_s).reject(&:blank?).uniq
    self.in_kind_donation_items = normalized_items
  end

  def validate_in_kind_donation_items
    return if in_kind_donation_items.blank?

    unsupported_items = Array(in_kind_donation_items).map(&:to_s).reject(&:blank?) - self.class.in_kind_donation_items_options.keys
    return if unsupported_items.empty?

    errors.add(:in_kind_donation_items, "contains unsupported item(s): #{unsupported_items.join(', ')}")
  end

  def attach_logo_and_cover
    unless cover_photo.attached?
      cover_photo.attach(io: File.open("app/assets/images/cover-default.png"), filename: "cover-default.png")
    end

    unless logo.attached?
      file_logo = "logo-default#{rand(1..6)}"
      filepath = File.open("app/assets/images/#{file_logo}.png")
      logo.attach(io: filepath, filename: "#{file_logo}.png")
    end
  end
end
