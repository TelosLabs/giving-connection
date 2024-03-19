# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.0"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem "rails", "~> 6.1.7"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use Puma as the app server
gem "puma", "~> 5.6"
# Use SCSS for stylesheets
gem "sass-rails", ">= 6"
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem "webpacker", "~> 5.0"
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.7"
# Use Redis adapter to run Action Cable in production
gem "redis", "~> 4.0"
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Use Devise for authentication
gem "devise"

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
gem "mobility", "~> 1.1.3"
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
gem "view_component"
# Use Turbo for rails
gem "turbo-rails"

gem "net-imap", require: false
gem "net-pop", require: false
gem "net-smtp", require: false

# Use administrate admin framework
gem "administrate"
gem "administrate-field-active_storage"
gem "administrate-field-nested_has_many", git: "https://github.com/TelosLabs/administrate-field-nested_has_many.git", branch: "feature/stimulus-controller"
gem "administrate-field-select", "~> 2.0", require: "administrate/field/select_basic"
gem "image_processing"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false
gem "city-state"
gem "pronto"
gem "pronto-flay", require: false
gem "pronto-rubocop", require: false

# Geolocation
gem "activerecord-postgis-adapter"

# Instagram feed
gem "koala"

group :development, :test do
  eval_gemfile "gemfiles/rubocop.gemfile"
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "factory_bot_rails"
  gem "pry-rails"
  gem "rspec-rails", "~> 5.0.0"
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
  gem "annotate"
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
  # Easy installation and use of web drivers to run system tests with browsers
  gem "rails-controller-testing"
  gem "rspec-sidekiq"
  gem "rspec-retry"
  gem "shoulda-matchers", "~> 4.0"
  gem "simplecov", require: false
  gem "test-prof", "~> 1.0"
  gem "timecop"
  gem "webdrivers", "~> 5.2", require: false
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
