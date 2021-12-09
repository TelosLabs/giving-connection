# frozen_string_literal: true

# == Schema Information
#
# Table name: alerts
#
#  id                 :bigint           not null, primary key
#  user_id            :bigint           not null
#  distance           :string
#  city               :string
#  state              :string
#  services           :string
#  open_now           :string
#  open_weekends      :string
#  keyword            :string
#  beneficiary_groups :string
#  frequency          :string           default("weekly")
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  next_alert         :date
#
class Alert < ApplicationRecord
  belongs_to :user

  validates :frequency, presence: true, inclusion: { in: %w[daily weekly monthly] }

  scope :due_for_today, -> { where(next_alert: Date.today) }

  after_commit :schedule_next_alert

  private

  def schedule_next_alert
    case frequency
    when 'daily'
      self.update_column(:next_alert, Date.today + 1)
    when 'weekly'
      self.update_column(:next_alert, Date.today + 7)
    when 'monthly'
      self.update_column(:next_alert, Date.today + 30)
    end
  end
end
