# frozen_string_literal: true

class Instagram::CreateMediaPostJob < ApplicationJob
  queue_as :default

  def perform(post)
    @post = post
    create_instagram_post
  end

  private

  def create_instagram_post
    instagram_post = InstagramPost.find_or_initialize_by(external_id: @post['id'])
    instagram_post.assign_attributes(post_attributes)
    instagram_post.save!
    Rails.logger.info "Successfully saved Instagram Post with id #{instagram_post.id}"
  end

  def post_attributes
    {
      external_id: @post['id'].to_i,
      media_url: @post['media_url'],
      post_url: @post['permalink'],
      media_type: @post['media_type'].downcase,
      creation_date: @post['timestamp'].to_date,
      updated_at: DateTime.current
    }
  end
end
