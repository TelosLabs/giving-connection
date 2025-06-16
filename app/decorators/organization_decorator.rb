class OrganizationDecorator < ApplicationDecorator
  delegate_all

  def donation_link
    link = object.donation_link.to_s
    return "mailto:#{link}" if link.match?(/\A[^@\s]+@[^@\s]+\z/)
    url_or_nil(link)
  end

  def volunteer_link
    url_or_nil(object.volunteer_link)
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

  private

  def url_or_nil(link)
    uri = URI.parse(link)
    return link if uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError, TypeError
    nil
  end

end
