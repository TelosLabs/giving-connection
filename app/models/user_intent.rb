# frozen_string_literal: true

class UserIntent
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :state, :city, :travel_bucket, :user_type,
    :causes_selected, :prefs_selected, :language_input

  validates :user_type, presence: true,
    inclusion: {in: %w[service_seeker volunteer donor]}
  validates :state, presence: true
  validates :causes_selected, presence: true

  # Embedding-text construction tuning. The total length cap is shared with
  # Organization#smart_match_text via SmartMatch::EMBEDDING_TEXT_MAX_LENGTH so
  # both ends of the embedding pipeline use the same character budget.
  EMBEDDING_TEXT_MAX_LENGTH = SmartMatch::EMBEDDING_TEXT_MAX_LENGTH
  # Reserve up to this many characters for the user's free-text input so it
  # is never truncated away by long cause / synonym lists.
  EMBEDDING_LANGUAGE_INPUT_BUDGET = 500
  PRIMARY_CAUSE_WEIGHT = 3

  # Build a UserIntent from session-shaped answers. Replaces the old
  # SmartMatch::QuizToUserIntentConverter service -- the conversion is a pure
  # function of one object's worth of input, which is exactly the shape that
  # belongs on the model rather than wrapped in a service.
  def self.from_session(session_answers:, user_type:)
    answers = session_answers.with_indifferent_access
    new(
      user_type: user_type,
      state: answers[:state],
      city: answers[:city],
      travel_bucket: answers[:travel_bucket],
      causes_selected: parse_array(answers[:causes]),
      prefs_selected: parse_array(answers[:prefs]),
      language_input: answers[:language_input]
    )
  end

  # Render this intent as embedding-ready text. Replaces SmartMatch::QuizTextBuilder.
  # Free-text goes at the front (BGE attends earlier tokens more heavily) and
  # is capped at EMBEDDING_LANGUAGE_INPUT_BUDGET so synonym expansion never
  # crowds it out. Structured parts (weighted causes, location, prefs) share
  # the remaining budget up to EMBEDDING_TEXT_MAX_LENGTH.
  def to_embedding_text
    free_text = Array(language_input).join(" ").strip
    free_text = free_text.truncate(EMBEDDING_LANGUAGE_INPUT_BUDGET) if free_text.length > EMBEDDING_LANGUAGE_INPUT_BUDGET

    remaining_budget = EMBEDDING_TEXT_MAX_LENGTH - (free_text.empty? ? 0 : free_text.length + 3) # " | " separator

    structured_parts = []
    structured_parts.concat(weighted_causes)
    structured_parts << location_text if location_text.present?
    structured_parts.concat(prefs)

    structured_text = structured_parts.compact_blank.join(" | ").truncate([remaining_budget, 0].max)

    pieces = []
    pieces << free_text unless free_text.empty?
    pieces << structured_text unless structured_text.empty?
    pieces.join(" | ")
  end

  def self.parse_array(value)
    Array(value).map(&:strip).compact_blank
  end

  private

  def weighted_causes
    Array(causes_selected).flat_map { |cause| expand_cause(cause) * PRIMARY_CAUSE_WEIGHT }
  end

  def expand_cause(cause)
    mapping = cause_mappings[cause]
    return [cause] unless mapping

    synonyms = Array(mapping["synonyms"])
    [cause] + synonyms
  end

  def prefs
    Array(prefs_selected).compact_blank
  end

  def location_text
    @location_text ||= [city, state].map(&:presence).compact.join(", ")
  end

  def cause_mappings
    SmartMatch::MATCHING_RULES.fetch("cause_mappings", {})
  end
end
