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
class OrganizationCategory < ApplicationRecord
  belongs_to :organization
  belongs_to :category
end
