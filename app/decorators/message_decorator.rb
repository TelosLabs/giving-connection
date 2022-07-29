class MessageDecorator < ApplicationDecorator
  delegate_all

  def real_subject
    case subject
    when '1' then 'I want to publish a nonprofit on Giving Connection'
    when '2' then 'I want to claim ownership of a nonprofit page'
    when '3' then 'Other'
    end
  end
end
