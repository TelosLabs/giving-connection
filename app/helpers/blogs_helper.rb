module BlogsHelper
  def user_avatar(user, size: 'w-8 h-8')
    if user&.avatar&.attached?
      image_tag(user.avatar, alt: "User Avatar", class: "object-cover #{size} rounded-full")
    else
      name = user.try(:name) || 'Anonymous'
      initials = name.split.map(&:first).join.upcase.first(2)
      
      colors = [
        'bg-blue-500', 'bg-green-500', 'bg-purple-500', 'bg-pink-500', 
        'bg-indigo-500', 'bg-red-500', 'bg-yellow-500', 'bg-teal-500'
      ]
      color = colors[name.sum % colors.length]
      
      content_tag(:div, initials, class: "#{size} rounded-full #{color} text-white flex items-center justify-center font-semibold text-sm")
    end
  end
end
