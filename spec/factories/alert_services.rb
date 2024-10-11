FactoryBot.define do
  factory :alert_service do
    alert { association(:alert) }
    service { association(:service) }
  end
end
