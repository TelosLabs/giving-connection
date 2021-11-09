class Service < ApplicationRecord
  belongs_to :cause
  has_many :location_services, dependent: :destroy
end
