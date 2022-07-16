# frozen_string_literal: true

class DeliveringMessage < SimpleDelegator
  def save
    if __getobj__.save
      MessageMailer.default_response(__getobj__).deliver_now
      MessageMailer.admins_notification(__getobj__).deliver_now
    end
  end
end
