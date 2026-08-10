# frozen_string_literal: true

module SmartMatchHelper
  def segment_fill_pct(section_steps, seg, current_section_number, step)
    return 0 if section_steps.empty? || seg > current_section_number
    return 100 if seg < current_section_number

    (section_steps.count { |s| s <= step }.to_f / section_steps.size * 100).round
  end

  def segment_prev_fill_pct(section_steps, seg, current_section_number, step)
    return segment_fill_pct(section_steps, seg, current_section_number, step) unless seg == current_section_number

    (section_steps.count { |s| s < step }.to_f / section_steps.size * 100).round
  end

  # Human-readable label for one criterion on the results page.
  #
  # Most quiz answers are tokens with a locale entry under
  # smart_match.quiz.steps.<question>.options.<answer>. Causes and services are
  # the exceptions: their "token" is already the display name (a real Cause or
  # Service preset), so they are shown as-is.
  SELF_LABELLING_CRITERIA = %w[causes services].freeze

  # Session answer keys whose locale block is named differently from the key
  # itself. Only these two diverge; everything else matches.
  CRITERION_LOCALE_KEYS = {
    "prefs" => "preferences",
    "donation_style" => "donor_giving_style",
    # Personal Details share one partial, so their options are nested under it.
    "age_range" => "final.age_range",
    "gender_identity" => "final.gender_identity",
    "race_ethnicity" => "final.race_ethnicity"
  }.freeze

  def smart_match_criterion_label(question, answer)
    # Proportional questions collapse all their answers into one row, so there
    # is no single answer to name -- label the question instead.
    return t("smart_match.results.criteria.groups.#{question}") if answer.blank?

    return answer if SELF_LABELLING_CRITERIA.include?(question)

    step = CRITERION_LOCALE_KEYS.fetch(question, question)
    t("smart_match.quiz.steps.#{step}.options.#{answer}", default: answer.to_s.humanize)
  end

  # Colour + glyph per aggregate status. Kept here rather than in the template
  # so the four states stay defined in one place.
  #
  # Partial shares the full match's checkmark and differs only in colour: a
  # partial match is still a match, and a distinct glyph made it read as a
  # third kind of failure. Colour never carries the meaning on its own -- the
  # sr-only label and the status text beside each row both name it.
  def smart_match_criterion_style(status)
    case status
    when "met" then {icon: "✓", classes: "text-green-700", aria: t("smart_match.results.criteria.status.met")}
    when "partial" then {icon: "✓", classes: "text-yellow-600", aria: t("smart_match.results.criteria.status.partial")}
    when "unknown" then {icon: "?", classes: "text-gray-4", aria: t("smart_match.results.criteria.status.unknown")}
    else {icon: "✕", classes: "text-red-600", aria: t("smart_match.results.criteria.status.unmet")}
    end
  end
end
