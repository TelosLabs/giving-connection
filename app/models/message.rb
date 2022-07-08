# frozen_string_literal: true

# == Schema Information
#
# Table name: messages
#
#  id                   :bigint           not null, primary key
#  name                 :string           not null
#  email                :string           not null
#  phone                :string
#  subject              :string
#  organization_name    :string           not null
#  organization_website :string
#  organization_ein     :string
#  content              :text
#
class Message < ActiveRecord::Base
  validates :name, presence: true
  validates :email, presence: true
end
