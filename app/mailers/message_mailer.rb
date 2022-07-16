# frozen_string_literal: true

class MessageMailer < ApplicationMailer
  default to: -> { AdminUser.pluck(:email) },
          from: 'Giving Connection <info@givingconnection.org>'

  def default_response(message)
    @message = message
    @body = mandrill_template("test_template")
    mail(to: @message.email, subject: 'We received your message!', body: @body, content_type: "text/html")
  end

  def admins_notification(message)
    @message = message
    mail subject: 'Contact notification'
  end

  private

  def mandrill_template(template_name)
    mandrill = Mandrill::API.new(ENV["SMTP_PASSWORD"])
    mandrill.templates.render(template_name)["html"]
  end
end
