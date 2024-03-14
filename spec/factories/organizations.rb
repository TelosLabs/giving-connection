# frozen_string_literal: true

# == Schema Information
#
# Table name: organizations
#
# name                          :string
# ein_number                    :string
# irs_ntee_code                 :string
# mission_statement_en          :text
# mission_statement_es          :text
# vision_statement_en           :text
# vision_statement_es           :text
# tagline_e                     :text
# tagline_es                    :text
# description_en                :text
# description_es                :text
# impact                        :text
# website                       :string
# scope_of_working              :string
# created_by_id,                        null: false
# created_at,                           null: false
# updated_at                            null: false
# created_by_id, name: index_organizations_on_created_by_id
#

FactoryBot.define do
  factory :organization do
    name { "organization" }
    ein_number { "testing" }
    irs_ntee_code { "A90: Arts Services" }
    mission_statement_en { "testing" }
    vision_statement_en { "testing" }
    website { "testing" }
    scope_of_work { "International" }

    after(:build) do |organization|
      organization.locations << create(:location, organization: organization)
      organization.creator = create(:admin_user)
      organization.causes << build(:cause)
    end
  end
end
