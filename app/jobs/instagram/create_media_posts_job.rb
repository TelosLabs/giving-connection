# frozen_string_literal: true

class Instagram::CreateMediaPostsJob < ApplicationJob
  queue_as :default

  def perform(posts)
    @posts = posts
    create_instagram_posts
  end

  private

  def create_instagram_posts
    @posts.each do |post|
      next if InstagramPost.find_by(external_id: post['id'])

      attrs = post_attributes(post)
      new_post = InstagramPost.new(attrs)
      if new_post.save
        Rails.logger.info "Succesfully created Instagram Post with id #{new_post.id}"
      else
        Rails.logger.info "Unable to create Instagram Post with external id #{post['id']}"
      end
    end
  end

  def post_attributes(post)
    {
      external_id: post[:id].to_i,
      media_url: post[:media_url],
      post_url: post[:permalink],
      creation_date: post[:timestamp]&.to_date
    }
  end
end
