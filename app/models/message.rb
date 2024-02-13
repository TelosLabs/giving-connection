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
#  organization_name    :string           
#  organization_website :string
#  organization_ein     :string
#  content              :text      
#  profile_admin_name   :string           not null
#  profile_admin_email  :string           not null
#
class Message < ActiveRecord::Base
  attr_accessor :form_definition

  validates :name, presence: true
  validates :email, format: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
end
