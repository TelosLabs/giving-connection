class OrganizationCause < ApplicationRecord
  belongs_to :cause
  belongs_to :organization, optional: true
end
