require 'clockwork'
require './config/boot'
require './config/environment'

module Clockwork
  handler do |job, time|
    puts "Running #{job}, at #{time}"
  end

  configure do |config|
    config[:tz] = "US/Pacific"
  end

  error_handler do |error|
    Rollbar.error(error)
  end

  every(1.day, 'Send Alert for Saved Searches', at: "08:00") do
    Profiles::SendUpdateReminderEmailsJob.perform_later
  end

end