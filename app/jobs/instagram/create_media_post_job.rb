# frozen_string_literal: true

class Instagram::CreateMediaPostJob < ApplicationJob
  queue_as :default

  def perform(post)
    @post = post
    create_instagram_post
  end

  private

  def create_instagram_post
    return if InstagramPost.find_by(external_id: @post['id'])

    new_post = InstagramPost.new(post_attributes)
    if new_post.save!
      Rails.logger.info "Succesfully created Instagram Post with id #{new_post.id}"
    else
      Rails.logger.info "Unable to create Instagram Post with external id #{@post['id']}"
    end
  end

  def post_attributes
    {
      external_id: @post['id'].to_i,
      media_url: @post['media_url'],
      post_url: @post['permalink'],
      creation_date: @post['timestamp'].to_date
    }
  end
end
