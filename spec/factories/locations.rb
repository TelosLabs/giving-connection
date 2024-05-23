FactoryBot.define do
  factory :location do
    organization
    name { Faker::Company.name }
    address { "MyString" }
    latitude { 1.5 }
    longitude { 1.5 }
    lonlat { Geo.point(1.5, 1.5) }
    main { true }
    offer_services { true }
    traits_for_enum(:non_standard_office_hours, Location.non_standard_office_hours.keys)

    trait :with_office_hours do
      time_zone { "Eastern Time (US & Canada)" }
      after(:build) do |location|
        (0..6).each do |day|
          location.office_hours.build(day: day, open_time: "08:00", close_time: "17:00") # Ensure these attributes match your OfficeHour model
        end
      end
    end
  end
end
