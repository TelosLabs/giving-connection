# frozen_string_literal: true

class DeliveringMessage < SimpleDelegator
  def save
    update_message_subject(__getobj__)
    if __getobj__.save
      MessageMailer.default_response(__getobj__).deliver_later
      MessageMailer.admins_notification(__getobj__).deliver_later
    end
  end

  private

  def update_message_subject(message)
    message.subject = 'I want to publish a nonprofit on Giving Connection' if message.subject == '1'
    message.subject = 'I want to claim ownership of a nonprofit page' if message.subject == '2'
    message.subject = 'Other' if message.subject == '3'
    message
  end
end
