# frozen_string_literal: true

FactoryBot.define do
  factory :feedback do
    rating { 4 }
    category { "search_results" }
    context { "search" }
    comment { "Really helpful, thanks!" }
    page_url { "https://example.com/search" }
  end
end
