class OrganizationCause < ApplicationRecord
  belongs_to :cause
  belongs_to :organization
end
