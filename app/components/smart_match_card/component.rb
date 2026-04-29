# frozen_string_literal: true

class SmartMatchCard::Component < ApplicationViewComponent
  attr_reader :organization, :match, :user_type

  def initialize(organization:, match:, user_type: nil)
    @organization = organization
    @match = match
    @user_type = user_type
  end

  def match_percentage
    (match.score * 100).round
  end

  def match_label
    case match_percentage
    when 80..100 then "Strong Match"
    when 60..79  then "Good Match"
    else              "Match"
    end
  end

  def match_label_color
    match_percentage >= 80 ? "text-teal-600" : "text-blue-medium"
  end

  def circle_circumference
    (2 * Math::PI * 20).round(2)
  end

  def circle_dash_offset
    (circle_circumference * (1 - [match.score, 1.0].min)).round(2)
  end

  def circle_color
    match_percentage >= 80 ? "#0d9488" : "#0782D0"
  end

  # CTA
  def cta_text
    case user_type
    when "donor"          then "Donate"
    when "volunteer"      then "Volunteer"
    when "service_seeker" then "Find Help"
    else                       "Learn More"
    end
  end

  def cta_classes
    case user_type
    when "donor"
      "bg-purple-100 hover:bg-purple-200 text-purple-800"
    when "volunteer"
      "bg-green-100 hover:bg-green-200 text-green-800"
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
    organization.causes.limit(4)
  end

  def cause_svg_name(cause)
    "#{cause.name.parameterize(separator: "_")}.svg"
  end

  def verified?
    organization.verified?
  end
end
