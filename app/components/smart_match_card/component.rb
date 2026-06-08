# frozen_string_literal: true

class SmartMatchCard::Component < ApplicationViewComponent
  attr_reader :organization, :match, :user_type

  CIRCLE_CIRCUMFERENCE = (2 * Math::PI * 20).round(2)

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
    when 75..100 then "Great Match"
    when 50..74 then "Good Match"
    else "Possible Match"
    end
  end

  def match_label_color
    case match_percentage
    when 75..100 then "text-seafoam"
    when 50..74 then "text-blue-medium"
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
    when 75..100 then "#9ae2e0"
    when 50..74 then "#0782D0"
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
  def location_address
    organization.main_location&.address
  end

  def phone_number
    organization.main_location&.phone_number&.number
  end

  def top_causes
    # Array#first serves from the preloaded association cache; limit() would
    # issue a fresh SELECT with LIMIT 4 and bypass the preload.
    organization.causes.first(4)
  end

  def cause_svg_name(cause)
    "#{cause.name.parameterize(separator: "_")}.svg"
  end

  def verified?
    organization.verified?
  end

  private

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
