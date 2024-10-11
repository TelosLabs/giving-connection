FactoryBot.define do
  factory :office_hour do
    # 0 => 'Sunday', 1 => 'Monday',..., 6 => 'Saturday'
    day { rand(6) }
    open_time { "09:00" }
    close_time { "17:00" }
    location
  end
end
