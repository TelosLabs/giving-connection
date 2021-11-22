# frozen_string_literal: true

# == Schema Information
#
# Table name: organization_categories
#
#  id              :bigint           not null, primary key
#  organization_id :bigint           not null
#  category_id     :bigint           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
FactoryBot.define do
  factory :organization_category do
    organization { association :organization }
    category { association :category }
  end
end
