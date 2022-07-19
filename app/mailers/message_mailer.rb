# frozen_string_literal: true

require 'mandrill'

class MessageMailer < ApplicationMailer
  default to: -> { AdminUser.pluck(:email) },
          from: 'Giving Connection <info@givingconnection.org>'

  def default_response(message)
    @message = message
    @body = mandrill_template('contact_form_confirmation')
    mail(to: @message.email, subject: 'We received your message!', body: @body, content_type: 'text/html')
  end

  def admins_notification(message)
    @message = message
    mail subject: 'Contact notification'
  end

  private

  def mandrill_template(template_name)
    mandrill = Mandrill::API.new(Rails.application.credentials.dig(:mailchimp, :api_key))
    attributes = { 'FIRST_NAME' => @message.name,
                   'EMAIL' => @message.email,
                   'SUBJECT' => @message.subject,
                   'MESSAGE' => @message.content,
                   'PHONE' => @message.phone }
    merge_vars = attributes.map { |key, value| { name: key, content: value } }
    mandrill.templates.render(template_name, [], merge_vars)['html']
  end
end
