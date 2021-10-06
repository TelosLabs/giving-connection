# frozen_string_literal: true

FactoryBot.define do
  factory :social_media do
    facebook { 'facebook.com/ong' }
    instagram { 'instagram.com/ong' }
    twitter { 'twitter.com.ong' }
    linkedin { 'linkedin.com/ong' }
    youtube { 'youtube.com/ong' }
    blog { 'blog-ong.com' }
    organization { association :organization }
  end
end
