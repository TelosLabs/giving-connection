class SmartMatchCard::ActionsMenu::Component < ApplicationViewComponent
  include ActionButtonHelper

  def initialize(user:, location:)
    @user = user
    @location = location
  end

  def website_action_params
    existing_website_url = @location.decorate.website || @location.organization&.decorate&.website
    {
      href: existing_website_url || "javascript:void(0);",
      target: ("_blank" if existing_website_url),
      button_styles: existing_website_url ? action_button_styles[:button] : "relative grid place-items-center pb-4 text-gray-4 cursor-auto",
      icon_wrapper_styles: existing_website_url ? action_button_styles[:icon_wrapper] : "w-10 h-10 border border-gray-4",
      icon_styles: ("disabled-icon" unless existing_website_url)
    }
  end
end
