class OrganizationDecorator < ApplicationDecorator
  delegate_all

  def donation_link
    object.decorate.url(object.donation_link)
  end

  def volunteer_link
    object.decorate.url(object.volunteer_link)
  end

  def designation_copies
    case object.scope_of_work
    when "National"
      {
        tag_copy: "Nationwide",
        desc_copy: "nationwide"
      }
    when "International"
      {
        tag_copy: "International",
        desc_copy: "internationally"
      }
    when "Regional"
      {
        tag_copy: "Regional",
        desc_copy: "locally"
      }
    end
  end
end
