class Organization < ApplicationRecord
  
  belongs_to :created_by, class_name: "User"

  validates :ein_number, uniqueness: true

end
