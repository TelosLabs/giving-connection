# frozen_string_literal: true

# == Schema Information
#
# Table name: beneficiary_groups
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :beneficiary_group do
    name { "Age" }
  end
end
