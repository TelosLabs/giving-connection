# UserIntent represents the structured preferences from the quiz
# This is a neutral struct that can be used by different recommendation algorithms
class UserIntent
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :user_state, :string
  attribute :user_city, :string
  attribute :travel_bucket, :string
  attribute :user_type, :string
  attribute :causes_selected, array: true, default: -> { [] }
  attribute :prefs_selected, array: true, default: -> { [] }
  attribute :language_input, :string

  validates :user_state, presence: true, inclusion: {in: %w[NJ CA TN]}
  validates :user_city, presence: true
  validates :travel_bucket, presence: true, inclusion: {in: %w[walk transit car]}
  validates :user_type, presence: true, inclusion: {in: %w[seeker volunteer donor]}
  validates :causes_selected, presence: true
  validates :prefs_selected, presence: true

  def initialize(attributes = {})
    super
    @causes_selected ||= []
    @prefs_selected ||= []
  end

  def to_s
    "UserIntent(#{user_type} in #{user_city}, #{user_state} - #{travel_bucket} travel, causes: #{causes_selected.join(", ")}, prefs: #{prefs_selected.join(", ")})"
  end

  def valid_state?
    %w[NJ CA TN].include?(user_state)
  end

  def valid_travel_bucket?
    %w[walk transit car].include?(travel_bucket)
  end

  def valid_user_type?
    %w[seeker volunteer donor].include?(user_type)
  end

  def has_language_preference?
    language_input.present?
  end

  def language_preference
    language_input&.downcase
  end
end
