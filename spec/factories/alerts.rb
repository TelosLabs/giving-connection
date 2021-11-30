# frozen_string_literal: true

# == Schema Information
#
# Table name: alerts
#
#  id                 :bigint           not null, primary key
#  user_id            :bigint           not null
#  distance           :string
#  city               :string
#  state              :string
#  services           :string
#  open_now           :string
#  open_weekends      :string
#  keyword            :string
#  beneficiary_groups :string
#  frequency          :string           default("weekly")
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
FactoryBot.define do
  factory :alert do
    user { nil }
    distance { 'MyString' }
    city { 'MyString' }
    state { 'MyString' }
    services { 'MyString' }
    open_now { 'MyString' }
    open_weekends { 'MyString' }
    keyword { 'MyString' }
    frequency { 'MyString' }
  end
end
