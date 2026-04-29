class NewsletterMailer < ApplicationMailer
  def verification_email(newsletter)
    @newsletter = newsletter
    @verification_url = verify_newsletter_subscription_url(token: newsletter.verification_token)

    mail(to: @newsletter.email, subject: "Confirm your newsletter subscription")
  end
end
