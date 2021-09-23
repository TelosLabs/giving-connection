# == Schema Information
#
# Table name: organizations
#
# name               :string
# ein_number         :string
# irs_ntee_code      :string
# mission_statement  :text
# vision_statement   :text
# tagline            :text
# description        :text
# impact             :text
# website            :string
# scope_of_working   :string
# created_by_id,              null: false
# created_at,                 null: false
# updated_at                  null: false
# created_by_id, name: index_organizations_on_created_by_id
#

FactoryBot.define do
  factory :organization do
    name { 'user@example.com' }
    ein_number { 'testing' }
    irs_ntee_code { 'testing' }
    mission_statement { 'testing' }
    vision_statement { 'testing' }
    tagline { 'testing' }
    description { 'testing' }
    impact { 'testing' }
    website { 'testing' }
    scope_of_working { 'testing' }
    created_by { association :user }
  end
end