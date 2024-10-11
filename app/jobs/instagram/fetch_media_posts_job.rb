# frozen_string_literal: true

class Instagram::FetchMediaPostsJob < ApplicationJob
  queue_as :default

  def perform
    FetchInstagramMedia.new.latest_media_posts
      .each { |post| Instagram::CreateMediaPostJob.perform_later(post) }
  end
end
