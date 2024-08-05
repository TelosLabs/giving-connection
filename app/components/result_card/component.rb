# frozen_string_literal: true

class ResultCard::Component < ApplicationViewComponent
  include ApplicationHelper

  def initialize(title:, address:, public_address:, link_to_google_maps:,
    image_url:, website:, description:, id:, current_user:, phone_number:,
    verified:, po_box:, causes: [], turbo_frame: {})
    @title = title
    @address = address
    @public_address = public_address
    @link_to_google_maps = link_to_google_maps
    @image_url = image_url
    @website = website
    @id = id
    @description = description
    @current_user = current_user
    @phone_number = phone_number
    @verified = verified
    @po_box = po_box
    @causes = causes
    # If not targeting a turbo-frame, don't provide this parameter
    @turbo_frame = turbo_frame
    @website_for_display = website_for_display
  end

  def formated_description
    (@description.length <= 280) ? @description : "#{@description[0..280]} (...)"
  end

  def website_for_display
    return @website if @website.blank? || @website&.length&.<(40)

    @website.truncate(40)
  end
end
