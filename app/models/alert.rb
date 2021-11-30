# frozen_string_literal: true

class Alert < ApplicationRecord
  belongs_to :user

  validates :frequency, presence: true, inclusion: { in: %w[daily weekly monthly] }
end
