# frozen_string_literal: true

class OrganizationAdmin < ApplicationRecord
  belongs_to :organization
  belongs_to :user
end
