class MessageDecorator < ApplicationDecorator
  delegate_all

  def real_subject
    case subject
    when "1" then "I’m looking for help from a nonprofit organization."
    when "2" then "I want to add a nonprofit to Giving Connection."
    when "3" then "I want to claim ownership of a nonprofit profile on Giving Connection."
    when "4" then "Other"
    end
  end
end
