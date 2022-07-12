# frozen_string_literal: true

require 'clockwork'
require './config/boot'
require './config/environment'

module Clockwork
  handler do |job, time|
    puts "Running #{job}, at #{time}"
  end

  configure do |config|
    config[:tz] = 'Eastern Time (US & Canada)'
  end

  error_handler do |error|
    Rollbar.error(error)
  end

  every(1.day, 'Send Alert for Saved Searches', at: '08:00') do
    Alert.due_for_today.each do |alert|
      Alerts::SendSavedSearchesAlertEmailsJob.perform_later(alert.id)
    end
  end

  every(3.hours, 'Fetch Instagram Media Posts') do
    Instagram::FetchMediaPostsJob.perform_later
  end
end
