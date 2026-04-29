# frozen_string_literal: true

class UserIntent
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :state, :city, :travel_bucket, :user_type,
    :causes_selected, :prefs_selected, :language_input

  validates :user_type, presence: true,
    inclusion: {in: %w[service_seeker volunteer donor]}
  validates :state, presence: true
  validates :causes_selected, presence: true
end
