class Organization < ApplicationRecord
  belongs_to :user

  validates :ein_number, uniqueness: true

  extend Mobility
  translates :mission_statement, type: :text
  translates :vision_statement, type: :text
  translates :tagline_statement, type: :text
  translates :description_statement, type: :text
  
end
