# frozen_string_literal: true

class OrganizationCategory < ApplicationRecord
  belongs_to :organization
  belongs_to :category
end
