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
end
