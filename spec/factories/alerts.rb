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
#  next_alert         :date
#
FactoryBot.define do
  factory :alert do
    user
  end
end
