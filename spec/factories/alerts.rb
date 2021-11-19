FactoryBot.define do
  factory :alert do
    user { nil }
    distance { "MyString" }
    city { "MyString" }
    state { "MyString" }
    services { "MyString" }
    open_now { "MyString" }
    open_weekends { "MyString" }
    keyword { "MyString" }
    frequency { "MyString" }
  end
end
