module ActionButtonHelper
  def action_button_styles
    {
      button: "relative grid place-items-center pb-4 transition-colors",
      icon_wrapper: "icon w-10 h-10 border border-gray-2",
      copy: "absolute bottom-0 right-1/2 w-max text-xs transform translate-x-1/2"
    }
  end
end
