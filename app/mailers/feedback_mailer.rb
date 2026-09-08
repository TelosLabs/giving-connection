# frozen_string_literal: true

class FeedbackMailer < ApplicationMailer
  default to: -> { AdminUser.pluck(:email) },
    bcc: Rails.application.credentials.dig(:mailer, :notification_bcc),
    from: Rails.application.credentials.dig(:mailer, :from)

  def admin_notification(feedback)
    @feedback = feedback
    mail subject: subject_for(feedback), reply_to: feedback.email.presence
  end

  private

  def subject_for(feedback)
    ["New feedback: #{feedback.rating_label}", feedback.category_label].compact.join(" - ")
  end
end
