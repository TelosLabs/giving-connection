FactoryBot.define do
  factory :instagram_post do
    media_url { Faker::Internet.url }
    post_url { Faker::Internet.url }
    external_id { Faker::Number.number(digits: 10) }
    media_type { 'Some type' }
    creation_date { Time.now }
  end
end
