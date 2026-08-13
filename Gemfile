# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

def next?
  File.basename(__FILE__) == "Gemfile.next"
end

ruby "3.4.8"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
if next?
  gem "rails", "~> 8.0.5"
  gem "activerecord-postgis-adapter", "~> 11.0"
else
  gem "rails", "~> 7.2.3.2"
  gem "activerecord-postgis-adapter", "~> 10.0"
end
gem "next_rails"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use Puma as the app server
gem "puma", "~> 8.0"
# Use SCSS for stylesheets
# Bundle and transpile JS in Rails. Read more: https://github.com/rails/jsbundling-rails/tree/main
gem "jsbundling-rails"
gem "cssbundling-rails"
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.7"
# Use Redis adapter to run Action Cable in production
gem "redis", "~> 4.0"
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant

# Use Devise for authentication
gem "devise", "~> 5.0"

# User Auth
gem "invisible_captcha"
gem "recaptcha"

gem "activerecord-import"
gem "active_storage_validations"
gem "aws-sdk-s3", require: false
gem "caxlsx"
gem "clockwork"
gem "cocoon"
gem "draper"
gem "faker"
gem "inline_svg"
gem "mobility", "~> 1.2.9"
gem "name_of_person"
gem "pagy"
gem "pg_search"
gem "pundit"
gem "rack-attack"
gem "rollbar"
gem "roo", "~> 2.8.0"
gem "scout_apm"
gem "sidekiq", "<7"
gem "slim-rails"
gem "view_component", "~> 3.25"
# Use Turbo for rails
gem "turbo-rails"

gem "rack", "~> 2.2.23"
gem "uri", ">= 1.0.4"

gem "net-imap", require: false
gem "net-pop", require: false
gem "net-smtp", require: false

# Use administrate admin framework
if next?
  gem "administrate", "~> 1.0"
else
  gem "administrate", "~> 0.20.0"
end
gem "administrate-field-active_storage"
gem "image_processing", "~> 1.13"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false
gem "city-state"
gem "timezone", "~> 1.0" #  Timezone lookup based on geolocation
gem "timezone_finder"
gem "momentjs-rails"

# Geolocation
gem "geocoder"

# Instagram feed
gem "koala"

gem "sprockets-rails", require: "sprockets/railtie"
# Sass compilation for app/assets/**/*.scss. Was a transitive dependency of
# administrate < 1.0; administrate 1.0 dropped it, the app still needs it.
gem "sassc-rails"

group :development, :test do
  eval_gemfile "gemfiles/rubocop.gemfile"
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "factory_bot_rails"
  gem "pry-rails"
  gem "rspec-rails", "~> 6.1.0"
  gem "spring-commands-rspec"
  gem "dotenv"
end

group :development do
  gem "bundle-audit"
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "web-console", ">= 4.1.0"
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem "listen", "~> 3.3"
  gem "rack-mini-profiler", "~> 2.0"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "annotate" unless next?
  gem "better_errors"
  gem "binding_of_caller"
  gem "brakeman"
  gem "bullet"
  gem "database_consistency", require: false
  gem "guard-rspec", require: false
  gem "letter_opener"
  gem "spring"
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem "capybara", ">= 3.26"
  gem "cuprite"
  gem "selenium-webdriver", ">= 4.14"
  gem "rails-controller-testing"
  gem "rspec-sidekiq"
  gem "rspec-retry"
  gem "shoulda-matchers", "~> 4.0"
  gem "simplecov", require: false
  gem "test-prof", "~> 1.0"
  gem "timecop"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

gem "mini_magick"

gem "friendly_id", "~> 5.5"
