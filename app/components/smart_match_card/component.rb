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

  def match_badge_text
    case match_percentage
    when 80..100 then "Strong Match"
    when 60..79 then "Good Match"
    end
  end

  def match_badge_class
    case match_percentage
    when 80..100 then "bg-seafoam text-blue-dark"
    when 60..79 then "bg-blue-pale text-blue-dark"
    end
  end

  def cta_text
    user_type == "service_seeker" ? "Find Help" : "Learn More"
  end

  def cta_url
    return unless organization.main_location

    helpers.location_path(organization.main_location)
  end

  def top_causes
    organization.causes.limit(4).pluck(:name)
  end

  def location_display
    organization.main_location&.address
  end

  def logo_url
    if organization.logo.attached?
      Rails.application.routes.url_helpers.url_for(organization.logo)
    end
  end
end
