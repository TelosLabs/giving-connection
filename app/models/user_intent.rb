# frozen_string_literal: true

class UserIntent
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :state, :city, :travel_bucket, :user_type,
    :causes_selected, :prefs_selected, :language_input
  attr_writer :location_scope

  LOCATION_SCOPES = %w[local national international].freeze

  # Quiz answers carried through verbatim, keyed by their session answer name.
  #
  # The value is the form control's arity in the step partial: :multiple for a
  # checkbox group (name="foo[]"), :single for a radio/select. Getting this
  # wrong stores a bare string where the scorer expects a list (or vice versa),
  # so it is asserted against the partials in the quiz schema consistency spec.
  #
  # These are read by SmartMatch::RuleScorer via config/smart_match_scoring.yml.
  # They were previously collected by QuizNavigator into the session and then
  # dropped on the floor here -- every lookup sheet in the client's scoring
  # spec (docs/smart-match-scoring/) scores answers from this set.
  #
  # `causes` and `prefs` are deliberately absent: they predate this table and
  # keep their historical `*_selected` accessor names.
  QUIZ_ANSWERS = {
    services: :multiple,
    support_for: :single,
    self_description: :multiple,
    situation: :single,
    donation_style: :multiple,
    giving_inspiration: :multiple,
    donor_communities: :multiple,
    impact_location: :single,
    donor_involvement: :single,
    volunteer_involvement: :multiple,
    volunteer_type: :multiple,
    volunteer_format: :single,
    volunteer_time: :single,
    age_range: :single,
    gender_identity: :single,
    race_ethnicity: :single
  }.freeze

  attr_accessor(*QUIZ_ANSWERS.keys)

  validates :user_type, presence: true,
    inclusion: {in: %w[service_seeker volunteer donor]}
  # State is only required for a local (city-based) search. Nationwide /
  # international selections intentionally carry no specific location.
  validates :state, presence: true, if: :local?
  validates :causes_selected, presence: true

  # local (default) | national | international
  def location_scope
    @location_scope.presence || "local"
  end

  def local?
    location_scope == "local"
  end

  # Donors who answered "Anywhere" to "where should your donation make an
  # impact?" opted out of geography: the client's spec gives that answer "All
  # nonprofits" and "no geographic weight".
  #
  # Without this the answer was stored and ignored, and the donor flow's
  # next question (which community?) hard-filtered them to a single state --
  # the opposite of what they asked for. Only the donor path offers the
  # answer, so nobody else can opt out.
  def geographic_filtering?
    !(user_type.to_s == "donor" && impact_location.to_s == "anywhere")
  end

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

    attributes = {
      user_type: user_type,
      state: answers[:state],
      city: answers[:city],
      travel_bucket: answers[:travel_bucket],
      location_scope: answers[:location_scope],
      causes_selected: parse_array(answers[:causes]),
      prefs_selected: parse_array(answers[:prefs]),
      language_input: answers[:language_input]
    }

    QUIZ_ANSWERS.each do |key, arity|
      attributes[key] = (arity == :multiple) ? parse_array(answers[key]) : answers[key].presence
    end

    new(attributes)
  end

  # All quiz answers as a normalized {session_key => Array(values)} hash --
  # the shape SmartMatch::RuleScorer walks. Single-value answers are wrapped so
  # callers don't branch on arity, and blanks are dropped so an unanswered
  # question is indistinguishable from an absent one.
  def answers_by_key
    normalized = QUIZ_ANSWERS.keys.to_h { |key| [key.to_s, Array(public_send(key)).compact_blank] }
    normalized["causes"] = Array(causes_selected).compact_blank
    normalized["prefs"] = Array(prefs_selected).compact_blank
    # The chosen path is itself scorable (the Donor path rewards a usable
    # donation link), so it is exposed the same way as any other answer.
    normalized["user_type"] = Array(user_type).compact_blank
    normalized
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

  # "none" is the "prefer not to say / none apply" escape hatch. It is a UI
  # affordance only and carries no semantic signal, so keep it out of the
  # embedding text.
  def prefs
    Array(prefs_selected).compact_blank - ["none"]
  end

  def location_text
    @location_text ||= case location_scope
    when "national" then "Nationwide services"
    when "international" then "International services"
    else [city, state].map(&:presence).compact.join(", ")
    end
  end

  def cause_mappings
    SmartMatch::MATCHING_RULES.fetch("cause_mappings", {})
  end
end
