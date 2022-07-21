# frozen_string_literal: true

class MessageMailer < ApplicationMailer
  default to: -> { AdminUser.pluck(:email) },
          from: 'Giving Connection <info@givingconnection.org>'

  def default_response(message)
    @message = message
    attach_logos
    mail to: @message.email, subject: 'We received your message!'
  end

  def admins_notification(message)
    @message = message
    mail subject: 'Contact notification'
  end

  def attach_logos
    attachments.inline["giving_connection_logo.png"] = File.read("#{Rails.root}/app/assets/images/send_alert_logo.png")
    attachments.inline["facebook.jpg"] = File.read("#{Rails.root}/app/assets/images/facebook.jpg")
    attachments.inline["instagram.jpg"] = File.read("#{Rails.root}/app/assets/images/instagram.jpg")
    attachments.inline["twitter.jpg"] = File.read("#{Rails.root}/app/assets/images/twitter.jpg")
    attachments.inline["youtoube.jpg"] = File.read("#{Rails.root}/app/assets/images/youtoube.jpg")
  end
end
