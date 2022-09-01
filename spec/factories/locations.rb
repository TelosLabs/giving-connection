FactoryBot.define do
  factory :location do
    name { 'MyString' }
    address { 'MyString' }
    latitude { 1.5 }
    longitude { 1.5 }
    lonlat { 'MyString' }
    main { true }
    physical { true }
    offer_services { true }
    appointment_only { true }
  end
end
