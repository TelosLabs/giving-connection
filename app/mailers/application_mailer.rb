# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  before_action :attach_logos
  default from: Rails.application.credentials.dig(:mailer, :from)
  layout "mailer"

  private

  def attach_logos
    attachments.inline["giving_connection_logo.png"] = File.read(Rails.root.join("app/assets/images/send_alert_logo.png").to_s)
    attachments.inline["facebook.jpg"] = File.read(Rails.root.join("app/assets/images/facebook.jpg").to_s)
    attachments.inline["instagram.jpg"] = File.read(Rails.root.join("app/assets/images/instagram.jpg").to_s)
    attachments.inline["twitter.jpg"] = File.read(Rails.root.join("app/assets/images/twitter.jpg").to_s)
    attachments.inline["youtoube.jpg"] = File.read(Rails.root.join("app/assets/images/youtoube.jpg").to_s)
  end
end
