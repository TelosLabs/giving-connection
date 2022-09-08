FactoryBot.define do
  factory :alert_cause do
    alert { association(:alert)}
    cause { association(:cause)}
  end
end
