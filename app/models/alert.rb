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
  has_many :alert_services, dependent: :destroy
  has_many :services, through: :alert_services
  has_many :alert_beneficiaries, dependent: :destroy
  has_many :beneficiary_subcategories, through: :alert_beneficiaries
  has_many :alert_causes, dependent: :destroy
  has_many :causes, through: :alert_causes

  validates :frequency, presence: true, inclusion: {in: %w[daily weekly monthly]}

  scope :due_for_today, -> { where(next_alert: Date.today) }

  after_create_commit :schedule_next_alert

  accepts_nested_attributes_for :alert_services, allow_destroy: true
  accepts_nested_attributes_for :alert_beneficiaries, allow_destroy: true
  accepts_nested_attributes_for :alert_causes, allow_destroy: true

  private

  def schedule_next_alert
    case frequency
    when 'daily'
      self.update_column(:next_alert, Date.today + 1.day)
    when 'weekly'
      self.update_column(:next_alert, Date.today + 1.week)
    when 'monthly'
      self.update_column(:next_alert, Date.today + 1.month)
    end
  end
end
