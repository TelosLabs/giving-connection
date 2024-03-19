# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def device
    agent = request.user_agent
    return "tablet" if /(tablet|ipad)|(android(?!.*mobile))/i.match?(agent)
    return "mobile" if /Mobile/.match?(agent)
    "desktop"
  end

  # recaptcha gem doesn't work well with Turbo
  def turbo_disabled_urls
    [new_nonprofit_request_url, new_contact_message_url]
  end
end
