FactoryBot.define do
  factory :office_hour do
    day { 0 }
    start_time { '09:00' }
    end_time { '17:00' }
    location { association :location }
  end
end
