# frozen_string_literal: true

class Instagram::FetchMediaPostsJob < ApplicationJob
  queue_as :default

  after_perform do
    @posts.each do |post|
      Instagram::CreateMediaPostJob.perform_later(post)
    end
  end

  def perform
    @posts = FetchInstagramMedia.new.latest_media_posts
  end
end
