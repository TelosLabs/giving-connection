# frozen_string_literal: true

class Instagram::CreateMediaPostJob < ApplicationJob
  queue_as :default

  def perform(post)
    @post = post
    create_instagram_post
  end

  private

  def create_instagram_post
    instagram_post = InstagramPost.find_by(external_id: @post['id'])
    if instagram_post
      Rails.logger.info "Succesfully updated Instagram Post with id #{instagram_post.id}" if instagram_post.update!(post_attributes)
    else
      new_post = InstagramPost.new(post_attributes)
      Rails.logger.info "Succesfully created Instagram Post with id #{new_post.id}" if new_post.save!
    end
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
