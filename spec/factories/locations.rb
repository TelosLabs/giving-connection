FactoryBot.define do
  factory :location do
    name { 'MyString' }
    address { 'MyString' }
    latitude { 1.5 }
    longitude { 1.5 }
    lonlat { Geo.point(1.5, 1.5) }
    main { true }
    offer_services { true }
    non_standard_office_hours { 1 }
  end
end
