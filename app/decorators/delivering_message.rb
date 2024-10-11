# frozen_string_literal: true

class DeliveringMessage < SimpleDelegator
  def save
    if __getobj__.save
      MessageMailer.default_response(__getobj__).deliver_later
      MessageMailer.admins_notification(__getobj__).deliver_later
    end
  end
end
