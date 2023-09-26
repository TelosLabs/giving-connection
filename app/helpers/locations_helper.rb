module LocationsHelper
  def logo_link(turbo_frame, id, image_url)
    if device == 'mobile' || turbo_frame[:src].blank?
      link_to(
        location_path(id),
        class: 'text-base font-bold text-black cursor-pointer',
        target: '_blank'
      ) do
        image_tag image_url, class: 'object-contain w-full h-20'
      end
    else
      link_to(
        turbo_frame[:src],
        class: 'text-base font-bold text-black cursor-pointer',
        id: "new_favorite_location_logo#{id}",
        data: { turbo_frame: turbo_frame[:id] }
      ) do
        image_tag image_url, class: 'object-contain w-full h-20'
      end
    end
  end

  def title_link(turbo_frame, id, title)
    if device == 'mobile' || turbo_frame[:src].blank?
      link_to title, location_path(id), class: 'text-base font-bold text-black cursor-pointer', target: '_blank' 
    else
      link_to(
        turbo_frame[:src],
        class: 'text-base font-bold text-black cursor-pointer',
        id: "new_favorite_location_title#{id}}",
        data: { turbo_frame: turbo_frame[:id] }
      ) do
        title
      end
    end
  end
end
