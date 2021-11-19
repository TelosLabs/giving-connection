class Alert < ApplicationRecord
  belongs_to :user

  validates :frequency, presence: true, inclusion: { in: ['daily', 'weekly', 'monthly'] } 
end
