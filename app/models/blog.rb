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

  def related_blogs(limit: 3)
    base_scope = Blog.published.where.not(id: id)
    related = []

    if topic.present?
      related += base_scope.where(topic: topic).limit(limit).to_a
    end

    return related.take(limit) if related.size >= limit

    if impact_tag.present? && impact_tag.any?
      remaining = limit - related.size
      matching_impact = base_scope
        .where.not(id: related.map(&:id))
        .select { |blog| (blog.impact_tag & impact_tag).any? }
        .take(remaining)
      related += matching_impact
    end

    return related.take(limit) if related.size >= limit

    if blog_tag.present?
      remaining = limit - related.size
      related += base_scope
        .where(blog_tag: blog_tag)
        .where.not(id: related.map(&:id))
        .limit(remaining)
        .to_a
    end

    return related.take(limit) if related.size >= limit

    if user_id.present?
      remaining = limit - related.size
      related += base_scope
        .where(user_id: user_id)
        .where.not(id: related.map(&:id))
        .limit(remaining)
        .to_a
    end

    if related.size < limit
      remaining = limit - related.size
      related += base_scope
        .where.not(id: related.map(&:id))
        .order(created_at: :desc)
        .limit(remaining)
        .to_a
    end

    related.take(limit)
  end

  def seo_keywords_list
    return [] if seo_keywords.blank?

    seo_keywords
      .split(",")
      .map(&:strip)
      .reject(&:blank?)
  end
end
