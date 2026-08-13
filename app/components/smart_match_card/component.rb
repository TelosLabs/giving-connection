# frozen_string_literal: true

class SmartMatchCard::Component < ApplicationViewComponent
  attr_reader :organization, :match, :user_type

  CIRCLE_CIRCUMFERENCE = (2 * Math::PI * 20).round(2)

  # Match-tier percentage cutoffs. A score at or above GREAT_MATCH_THRESHOLD
  # is a "Great Match"; at or above GOOD_MATCH_THRESHOLD (but below great) is a
  # "Good Match"; anything lower is a plain "Match". Shared by the label, label
  # color, and circle color so the three presentations can't drift apart.
  GREAT_MATCH_THRESHOLD = 75
  GOOD_MATCH_THRESHOLD = 50

  def initialize(organization:, match:, user_type: nil)
    @organization = organization
    @match = match
    @user_type = user_type
  end

  def match_percentage
    (calibrated_fraction * 100).round
  end

  def match_label
    case match_percentage
    when GREAT_MATCH_THRESHOLD..100 then "Great Match"
    when GOOD_MATCH_THRESHOLD...GREAT_MATCH_THRESHOLD then "Good Match"
    else "Match"
    end
  end

  def match_label_color
    case match_percentage
    when GREAT_MATCH_THRESHOLD..100 then "text-seafoam"
    when GOOD_MATCH_THRESHOLD...GREAT_MATCH_THRESHOLD then "text-blue-medium"
    else "text-salmon"
    end
  end

  def circle_circumference
    CIRCLE_CIRCUMFERENCE
  end

  def circle_dash_offset
    (circle_circumference * (1 - calibrated_fraction)).round(2)
  end

  def circle_color
    case match_percentage
    when GREAT_MATCH_THRESHOLD..100 then "#9ae2e0"
    when GOOD_MATCH_THRESHOLD...GREAT_MATCH_THRESHOLD then "#0782D0"
    else "#fc8383"
    end
  end

  # CTA
  def cta_text
    case user_type
    when "donor" then "Donate"
    when "volunteer" then "Volunteer"
    when "service_seeker" then "Find Help"
    else "Learn More"
    end
  end

  def cta_classes
    case user_type
    when "donor"
      "bg-indigo-100 hover:bg-indigo-200 text-indigo-700"
    when "volunteer"
      "bg-seafoam hover:bg-electric-teal text-blue-dark"
    else
      # service_seeker + default
      "bg-salmon hover:bg-salmon-medium text-white"
    end
  end

  def cta_url
    return unless organization.main_location
    helpers.location_path(organization.main_location)
  end

  # Org profile (location page) — used by the logo and org name links.
  def profile_url
    return unless main_location
    helpers.location_path(main_location)
  end

  # Google Maps link for the address.
  def maps_url
    main_location&.link_to_google_maps
  end

  # Discover page for a cause (routes by Cause#to_param == name).
  def discover_cause_url(cause)
    helpers.discover_show_path(cause)
  end

  # Images
  def cover_photo_url
    return unless organization.cover_photo.attached?
    helpers.rails_blob_path(organization.cover_photo, only_path: true)
  end

  def logo_url
    return unless organization.logo.attached?
    helpers.rails_blob_path(organization.logo, only_path: true)
  end

  # Info
  def main_location
    organization.main_location
  end

  def location_address
    organization.main_location&.address
  end

  def phone_number
    organization.main_location&.phone_number&.number
  end

  # Why THIS organization surfaced -- the criteria it personally satisfies.
  #
  # Only the positives, and only a few up front -- the rest are one click away
  # behind the "+N more" toggle. Answers are OR'd rather than AND'd, so every
  # result meets some subset and the useful signal is which subset; the misses
  # are already reported once, in aggregate, by the results page panel.
  # Repeating them per card would triple the noise for no extra information.
  #
  # Ordered by what actually moved the score, so the most substantive reason
  # leads rather than whichever question happened to come first in the quiz.
  MAX_MATCH_REASONS = 3

  def match_reasons
    ordered_match_reasons.first(MAX_MATCH_REASONS)
  end

  # The remainder, rendered collapsed behind the "+N more" toggle. They ship
  # with the card rather than being fetched on expand: they are a handful of
  # short strings we have already computed, and hiding them client-side keeps
  # expanding instant and independent per card.
  def hidden_match_reasons
    ordered_match_reasons.drop(MAX_MATCH_REASONS)
  end

  def hidden_match_reason_count
    hidden_match_reasons.size
  end

  # Every chip in display order, flagged with whether it starts collapsed, so
  # the template renders one chip markup rather than two near-identical loops.
  def match_reason_chips
    match_reasons.map { |reason| [reason, false] } +
      hidden_match_reasons.map { |reason| [reason, true] }
  end

  def top_causes
    # Array#first serves from the preloaded association cache; limit() would
    # issue a fresh SELECT with LIMIT 4 and bypass the preload.
    organization.causes.first(4)
  end

  def cause_svg_name(cause)
    cause.decorate.svg_file_name
  end

  def verified?
    organization.verified?
  end

  private

  # Labels for everything this organization satisfies, strongest first.
  def ordered_match_reasons
    @ordered_match_reasons ||= satisfied_criteria
      .sort_by { |criterion| -contribution_for(criterion) }
      .map { |criterion| reason_label(criterion) }
  end

  # Criteria this organization personally satisfies, in full or in part.
  def satisfied_criteria
    @satisfied_criteria ||= Array(match.score_breakdown&.dig("criteria")).select do |criterion|
      criterion["status"].in?([SmartMatch::RuleScorer::MET, SmartMatch::RuleScorer::PARTIAL]) &&
        SmartMatch::CriteriaSummary::HIDDEN_QUESTIONS.exclude?(criterion["question"])
    end
  end

  # How much this criterion earned, read back from the itemized trace. Grouped
  # criteria (services) have no single answer, so they match on question alone.
  def contribution_for(criterion)
    Array(match.score_breakdown&.dig("rule_matches"))
      .select { |entry| entry["question"] == criterion["question"] }
      .select { |entry| criterion["answer"].blank? || entry["answer"] == criterion["answer"] }
      .sum { |entry| entry["contribution"].to_f }
  end

  def reason_label(criterion)
    # ApplicationController.helpers rather than the component's `helpers`
    # proxy: the latter needs an active render, and resolving a label is a pure
    # function of the answer plus the current locale.
    label = ApplicationController.helpers.smart_match_criterion_label(
      criterion["question"], criterion["answer"]
    )
    return label unless criterion["grouped"]

    "#{label} (#{criterion["matched_count"]}/#{criterion["selected_count"]})"
  end

  # The displayed match fraction (0.0–1.0) after presentation-only calibration.
  # Raw scores are dominated by compressed embedding similarity; the linear
  # rescale defined in matching_rules.yml#display_calibration stretches them
  # onto a more intuitive band. It is monotonic, so ranking is unaffected.
  def calibrated_fraction
    @calibrated_fraction ||= calibrate(match.score.to_f)
  end

  def calibrate(raw)
    raw = raw.clamp(0.0, 1.0)
    cfg = SmartMatch::MATCHING_RULES["display_calibration"]
    return raw unless cfg

    floor = cfg["input_floor"].to_f
    ceiling = cfg["input_ceiling"].to_f
    return raw if ceiling <= floor

    min_fraction = cfg["min_percentage"].to_f / 100.0
    max_fraction = cfg["max_percentage"].to_f / 100.0
    t = ((raw - floor) / (ceiling - floor)).clamp(0.0, 1.0)
    (min_fraction + t * (max_fraction - min_fraction)).clamp(0.0, 1.0)
  end
end
