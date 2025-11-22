module BlogsHelper
  def user_avatar(user, size: 'w-8 h-8', fallback_name: nil)
    if user&.avatar&.attached?
      image_tag(user.avatar, alt: "User Avatar", class: "object-cover #{size} rounded-full")
    else
      name = user&.name.presence || fallback_name.presence || 'Anonymous'
      if name == 'Anonymous'
        image_tag('anonymous-user.jpg', alt: "Anonymous User", class: "object-cover #{size} rounded-full")
      else
        initials = name.split.map(&:first).join.upcase.first(2)
        
        colors = [
          'bg-blue-500', 'bg-green-500', 'bg-purple-500', 'bg-pink-500', 
          'bg-indigo-500', 'bg-red-500', 'bg-yellow-500', 'bg-teal-500'
        ]
        color = colors[name.sum % colors.length]
        
        content_tag(:div, initials, class: "#{size} rounded-full #{color} text-white flex items-center justify-center font-semibold text-sm select-none")
      end
    end
  end

  def blog_filter_button(label, tag, icon)
    is_active = (@selected_tag == tag)
    count = (tag == 'all') ? Blog.published.count : Blog.published.where(blog_tag: tag).count
    
    link_to blogs_path(blog_tag: tag), class: "flex gap-1 px-3 py-2 text-xs border-[1px] border-solid rounded-full transition-colors #{is_active ? 'bg-blue-dark text-white border-blue-dark' : 'bg-white border-gray-5 text-gray-2 hover:border-blue-dark'}" do
      concat content_tag(:span, inline_svg_tag(icon, size: '15*15', class: (is_active ? 'fill-white' : 'text-blue-dark')),'aria-hidden': 'true')
      concat "#{label} (#{count})"
    end
  end
end
