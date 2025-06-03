# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string
#  last_sign_in_ip        :string
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string
#  locked_at              :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  name                   :string
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :omniauthable
  devise :database_authenticatable, :registerable, :recoverable,
    :rememberable, :validatable, :confirmable, :lockable, :trackable

  attr_accessor :terms_of_service
  validates :terms_of_service, acceptance: {accept: "1"}, on: :create

  # Validations
  validates :name, presence: true,
    length: {minimum: 2, maximum: 50},
    format: {with: /\A[a-zA-Z\s\-']+\z/, message: "can only contain letters, spaces, hyphens and apostrophes"}

  validate :no_urls_in_name

  has_many :organizations, as: :creator
  has_many :alerts
  has_many :fav_locs, class_name: "FavoriteLocation"
  has_many :favorited_locations, through: :fav_locs, source: :location
  has_many :organization_admin
  has_many :administrated_organizations, through: :organization_admin, source: :organization

  private

  def no_urls_in_name
    if name.present? && name.match?(/https?:\/\/|\.[a-z]{2,}/i)
      errors.add(:name, "cannot contain URLs or web links")
    end
  end
end
