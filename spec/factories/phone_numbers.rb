FactoryBot.define do
  factory :phone_number do
    number { "MyString" }
    main { false }
    contact_information { nil }
  end
end
