class NonprofitCard::ActionsMenu::Component < ViewComponent::Base
  def initialize(user:, location:)
    @user = user
    @location = location
  end

  def button_styles
    "interactive-btn group relative grid place-items-center pb-4 transition-colors hover:text-blue-medium"
  end

  def icon_wrapper_styles
    "icon w-10 h-10 border border-gray-2 transition-colors group-hover:bg-blue-medium group-hover:border-blue-medium"
  end

  def action_copy_styles
    "absolute bottom-0 right-1/2 w-max transform translate-x-1/2"
  end

  def website_action_params
    existing_website_url = @location.decorate.website || @location.organization&.decorate&.website
    {
      href: existing_website_url || "javascript:void(0);",
      target: ("_blank" if existing_website_url),
      button_styles: existing_website_url ? button_styles : "relative grid place-items-center pb-4 text-gray-4 cursor-auto",
      icon_wrapper_styles: existing_website_url ? icon_wrapper_styles : "w-10 h-10 border border-gray-4",
      icon_styles: ("disabled-icon" unless existing_website_url)
    }
  end
end
