FactoryBot.define do
  factory :office_hour do
    day { 0 }
    open_time { '09:00' }
    close_time { '17:00' }
    location { association :location }
  end
end
