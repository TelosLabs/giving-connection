# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'Giving Connection <info@givingconnection.org>'
  layout 'mailer'
end
