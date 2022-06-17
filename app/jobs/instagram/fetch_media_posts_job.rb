# frozen_string_literal: true

class Instagram::FetchMediaPostsJob < ApplicationJob
  queue_as :default

  after_perform do
    Instagram::CreateMediaPostsJob.perform_later(@posts)
  end

  def perform
   @posts = InstagramMedia.new.latest_media_posts
  end
end
