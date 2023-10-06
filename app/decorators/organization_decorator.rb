class OrganizationDecorator < ApplicationDecorator
  delegate_all

  def donation_link
    object.decorate.url(object.donation_link)
  end

  def volunteer_link
    object.decorate.url(object.volunteer_link)
  end
end
