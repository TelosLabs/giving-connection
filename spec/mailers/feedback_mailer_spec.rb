# frozen_string_literal: true

require "rails_helper"

RSpec.describe FeedbackMailer, type: :mailer do
  describe "#admin_notification" do
    let!(:admins) { create_list(:admin_user, 2) }
    let(:feedback) { create(:feedback, rating: 5, category: "ease_of_use", comment: "Loved it") }
    let(:mail) { described_class.admin_notification(feedback) }

    it "goes to every admin and bccs the notification address" do
      expect(mail.to).to match_array(admins.map(&:email))
      expect(mail.bcc).to eq([Rails.application.credentials.dig(:mailer, :notification_bcc)])
    end

    it "summarizes the feedback in the subject" do
      expect(mail.subject).to eq("New feedback: Love it - Ease of use")
    end

    it "drops the category from the subject when none was picked" do
      feedback.update!(category: nil)
      expect(mail.subject).to eq("New feedback: Love it")
    end

    it "includes the feedback content" do
      body = mail.body.encoded
      expect(body).to include("Loved it")
      expect(body).to include("Ease of use")
      expect(body).to include(feedback.page_url)
    end

    context "anonymous feedback" do
      it "labels the sender as anonymous and sets no reply-to" do
        expect(mail.body.encoded).to include("Anonymous visitor")
        expect(mail.reply_to).to be_nil
      end
    end

    context "feedback from a signed-in user" do
      before { feedback.update!(user: create(:user)) }

      it "shows their email and replies back to them" do
        expect(mail.body.encoded).to include(feedback.reload.email)
        expect(mail.reply_to).to eq([feedback.email])
      end
    end
  end
end
