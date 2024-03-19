# frozen_string_literal: true

# == Schema Information
#
# Table name: organization_admins
#
#  id              :bigint           not null, primary key
#  organization_id :bigint           not null
#  user_id         :bigint           not null
#  role            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
FactoryBot.define do
  factory :organization_admin do
    organization { association(:organization) }
    user { association(:user) }
    role { "MyString" }
  end
end
