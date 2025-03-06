class Event < ApplicationRecord
    belongs_to :organization
  
    validates :title, :start_time, :end_time, :organization, presence: true
  end
  