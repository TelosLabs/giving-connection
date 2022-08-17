# frozen_string_literal: true
class ResultCard::Component < ViewComponent::Base
  include ApplicationHelper

  def initialize(title:, address:, image_url:, website:, description:, id:, current_user:, phone_number:, verified: )
    # <span><%= image_tag 'verified_nonprofit_check.jpg', class: "w-4 h-4 ml-2" %></span>
    @title = verified ? "#{title}✅" : title
    @address = address
    @image_url = image_url
    @website = website
    @id = id
    @description = description
    @current_user = current_user
    @phone_number = phone_number
    @verified = verified
  end

  def website_url
    uri = URI(@website)

    if uri.instance_of?(URI::Generic)
      split = uri.to_s.split('/')
      if split.size > 1
        uri = URI::HTTP.build({host: split.shift, path: '/'+split.join('/')})
      else
        uri = URI::HTTP.build({host: split.shift.to_s})
      end
    end
    uri.to_s
  end

  def formated_description
    @description.length <= 280 ? @description : "#{@description[0..280]} (...)"
  end

  def logo
    data = open("http://www.gravatar.com/avatar/c2713a4959692f16d27d2553fb06cc4b.png?r=x&s=170")
    send_data data, type: image.content_type, disposition: 'inline'
  end
end
