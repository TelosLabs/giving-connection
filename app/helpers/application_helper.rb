# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def device
    agent = request.user_agent
    return "tablet" if agent =~ /(tablet|ipad)|(android(?!.*mobile))/i
    return "mobile" if agent =~ /Mobile/
    return "desktop"
  end

  # recaptcha gem doesn't work well with Turbo
  def turbo_disabled_urls
    [new_nonprofit_request_url, new_contact_message_url]
  end
end
