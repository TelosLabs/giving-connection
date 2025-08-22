# frozen_string_literal: true

require_relative "boot"
require_relative "../app/middleware/timezone_detector"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module GivingConnection
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1
    config.active_job.queue_adapter = :sidekiq
    config.active_storage.replace_on_assign_to_many = false
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "UTC"
    config.active_record.default_timezone = :utc
    # config.eager_load_paths << Rails.root.join("extras")

    config.i18n.default_locale = :en
    config.i18n.available_locales = %i[en es]
    config.autoload_paths += Dir.glob("#{config.root}/app/lib")
    config.assets.css_compressor = nil
    config.middleware.use TimezoneDetector
  end
end
