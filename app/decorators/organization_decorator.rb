class OrganizationDecorator < ApplicationDecorator
  delegate_all

  def donation_link
    object.decorate.url(object.donation_link)
  end

  def volunteer_link
    object.decorate.url(object.volunteer_link)
  end

  def scope_of_work
    {
      "National" => "nationwide",
      "International" => "internationally",
      "Regional" => "locally"
    }[object.scope_of_work]
  end
end
