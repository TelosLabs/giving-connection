# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'Giving Connection <info@givingconnection.org>'
  layout 'mailer'
  before_action :attach_logos

  private

  def attach_logos
    attachments.inline["giving_connection_logo.png"] = File.read("#{Rails.root}/app/assets/images/send_alert_logo.png")
    attachments.inline["facebook.jpg"] = File.read("#{Rails.root}/app/assets/images/facebook.jpg")
    attachments.inline["instagram.jpg"] = File.read("#{Rails.root}/app/assets/images/instagram.jpg")
    attachments.inline["twitter.jpg"] = File.read("#{Rails.root}/app/assets/images/twitter.jpg")
    attachments.inline["youtoube.jpg"] = File.read("#{Rails.root}/app/assets/images/youtoube.jpg")
  end
end
