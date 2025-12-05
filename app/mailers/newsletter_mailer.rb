class NewsletterMailer < ApplicationMailer
  default from: Rails.application.credentials.dig(:mailer, :from)
  
  def verification_email(newsletter)
    @newsletter = newsletter
    @verification_url = verify_newsletter_subscription_url(token: newsletter.verification_token)
    
    mail(to: @newsletter.email, subject: 'Confirm your newsletter subscription')
  end
end