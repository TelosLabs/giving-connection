FactoryBot.define do
  factory :comment do
    body { "MyText" }
    blog { nil }
    user { nil }
  end
end
