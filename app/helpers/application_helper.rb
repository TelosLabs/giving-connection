# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def device
    agent = request.user_agent
    return "tablet" if agent =~ /(tablet|ipad)|(android(?!.*mobile))/i
    return "mobile" if agent =~ /Mobile/
    return "desktop"
  end

  def turbo_disabled_urls
    [nonprofit_url, contact_url]
  end
end
