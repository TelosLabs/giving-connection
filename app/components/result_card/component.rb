# frozen_string_literal: true
class ResultCard::Component < ViewComponent::Base
  include ApplicationHelper

  def initialize(title:, address:, image_url:, website:, description:, id:, current_user:, phone_number:, verified:, causes: [], turbo_frame: {})
    @title = title
    @address = address
    @image_url = image_url
    @website = website
    @id = id
    @description = description
    @current_user = current_user
    @phone_number = phone_number
    @verified = verified
    @causes = causes
    # If not targeting a turbo-frame, don't provide this parameter
    @turbo_frame = turbo_frame
  end

  def formated_description
    @description.length <= 280 ? @description : "#{@description[0..280]} (...)"
  end
end
