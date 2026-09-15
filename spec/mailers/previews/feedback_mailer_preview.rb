# frozen_string_literal: true

class FeedbackMailerPreview < ActionMailer::Preview
  def admin_notification
    feedback = Feedback.new(
      rating: 4,
      category: "ease_of_use",
      context: "search",
      comment: "Finding a food bank near me took two clicks. The map was a little slow though.",
      page_url: "https://www.givingconnection.org/search?city=Nashville",
      created_at: Time.current
    )

    FeedbackMailer.admin_notification(feedback)
  end
end
