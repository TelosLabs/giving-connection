# Load general RSpec Rails configuration
require "rails_helper"

# Load configuration files and helpers
Dir[File.join(__dir__, "system/support/**/*.rb")].each { |file| require file }
