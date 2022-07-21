# frozen_string_literal: true

class MessageMailer < ApplicationMailer
  default to: -> { AdminUser.pluck(:email) },
          from: Rails.application.credentials.dig(:mailchimp, :username)

  def default_response(message)
    @message = message
    mail to: @message.email, subject: 'We received your message!'
  end

  def admins_notification(message)
    @message = message
    mail subject: 'Contact notification'
  end
end
