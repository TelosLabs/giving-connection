class Organization < ApplicationRecord
  extend Mobility
  translates :tagline,               type: :text
  translates :description,           type: :text
  translates :vision_statement,      type: :text
  translates :mission_statement,     type: :text

  belongs_to :created_by, class_name: "User"

  validates :ein_number, uniqueness: true
  
end
