# frozen_string_literal: true

FactoryBot.define do
  factory :quiz_submission do
    session_id { SecureRandom.hex(16) }
    user_type { "volunteer" }
    answers { {state: "TN", city: "Nashville", causes: ["Education"]} }
    embedding { Array.new(1024) { rand(-1.0..1.0) } }
    text_snapshot { "Education | Nashville, TN" }
    user { nil }
  end
end
