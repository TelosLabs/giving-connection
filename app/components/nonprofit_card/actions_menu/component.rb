class NonprofitCard::ActionsMenu::Component < ViewComponent::Base
  def initialize(user:, location:)
    @user = user
    @location = location
  end

  def button_styles
    "interactive-btn group grid place-items-center transition-colors hover:text-blue-medium"
  end

  def icon_wrapper_styles
    "icon w-10 h-10 border border-gray-2 transition-colors group-hover:bg-blue-medium group-hover:border-blue-medium"
  end
end
