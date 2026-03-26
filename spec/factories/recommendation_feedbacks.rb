FactoryBot.define do
  factory :recommendation_feedback do
    user { nil }
    nonprofit_id { "MyString" }
    feedback_type { "MyString" }
    session_id { "MyString" }
  end
end
