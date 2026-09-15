# frozen_string_literal: true

# == Schema Information
#
# Table name: search_terms
#
#  id                 :bigint           not null, primary key
#  keyword            :string           not null
#  normalized_keyword :string           not null
#  results_count      :integer          default(0), not null
#  origin             :string
#  city               :string
#  state              :string
#  filtered           :boolean          default(FALSE), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
FactoryBot.define do
  factory :search_term do
    keyword { "food pantry" }
    normalized_keyword { SearchTerm.normalize(keyword) }
    results_count { 3 }
    origin { "search_results" }
    city { "Nashville" }
    state { "Tennessee" }
    filtered { false }
  end
end
