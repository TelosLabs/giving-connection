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
    [new_contact_message_url]
  end

  def load_webpack_manifest
    JSON.parse(File.read("public/packs/manifest.json"))
  rescue Errno::ENOENT
    fail "The webpack manifest file does not exist." unless Rails.configuration.assets.compile
  end

  def webpack_manifest
    # Always get manifest.json on the fly in development mode
    return load_webpack_manifest if Rails.env.development?

    # Get cached manifest.json if available, else cache the manifest
    Rails.configuration.x.webpack.manifest || Rails.configuration.x.webpack.manifest = load_webpack_manifest
  end

  def webpack_asset_urls(asset_name, asset_type)
    webpack_manifest["entrypoints"][asset_name]["assets"][asset_type]
  end

  def get_timezone
    # Get the timezone from the request environment
    timezone = request.env["user_timezone"] || Time.zone.name

    # Set the user's timezone in the instance variable
    @user_timezone = timezone

    # Return the timezone
    timezone
  end

  def format_event_time(datetime)
    return "" if datetime.blank?

    datetime.in_time_zone(@user_timezone || Time.zone.name)
      .strftime("%^a, %^b %d, %Y at %l:%M %p")
      .gsub(/\s+/, " ")
      .strip
  end
end
