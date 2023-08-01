FactoryBot.define do
  factory :location do
    name { 'MyString' }
    address { 'MyString' }
    latitude { 1.5 }
    longitude { 1.5 }
    lonlat { Geo.point(1.5, 1.5) }
    main { true }
    physical { true }
    offer_services { true }
    appointment_only { true }
    always_open { false }
  end
end
