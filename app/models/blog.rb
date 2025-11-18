class Blog < ApplicationRecord
  belongs_to :user, optional: true
  has_rich_text :content
  has_many_attached :images
  has_one_attached :cover_image
  has_one_attached :thumbnail_image

  has_many :blog_likes, dependent: :destroy
  has_many :likers, through: :blog_likes, source: :user
  has_many :comments, dependent: :destroy

  has_many :favorite_blogs, dependent: :destroy

  attr_accessor :author_email
  attr_accessor :share_consent

  validates :title, presence: true
  validates :share_consent, acceptance: {accept: "1", message: "must be accepted to publish your story"}

  scope :published, -> { where(published: true) }

  attribute :impact_tag, :string, array: true, default: -> { [] }

  IMPACT_TAG_OPTIONS = [
    "Found a nonprofit to support",
    "Received help or resources",
    "Discovered a volunteer opportunity",
    "Made a community connection",
    "Found inspiration or purpose",
    "Reached new clients or volunteers",
    "Built a partnership or collaboration",
    "Promoted an event or program",
    "Increased visibility or awareness",
    "Supported disaster relief or recovery",
    "Other"
  ].freeze

  BLOG_TAG_OPTIONS = [
    "Nonprofits",
    "Community",
    "Staff"
  ].freeze

  def author_email
    @author_email || user&.email
  end

  validate :assign_user_from_author_email, if: -> { author_email.present? }

  private

  def assign_user_from_author_email
    found_user = User.find_by(email: author_email)

    if found_user
      self.user = found_user
      # Optional: sync name/email for display if blank
      self.name ||= found_user.name
      self.email ||= found_user.email
    else
      errors.add(:author_email, "no user found with that email")
    end
  end

end
