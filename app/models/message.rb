# frozen_string_literal: true

# == Schema Information
#
# Table name: messages
#
#  id                   :bigint           not null, primary key
#  name                 :string           not null
#  email                :string           not null
#  phone                :string
#  subject              :string           not null
#  organization_name    :string           not null
#  organization_website :string
#  organization_ein     :string
#  content              :text             not null
#  profile_admin_name   :string
#  profile_admin_email  :string
#
class Message < ActiveRecord::Base
  validates :name, presence: true
  validates :email, presence: true
  validates :subject, presence: true
  validates :organization_name, presence: true
  validates :content, presence: true
end
