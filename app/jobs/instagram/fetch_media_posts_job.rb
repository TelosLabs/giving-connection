# frozen_string_literal: true

class Instagram::FetchMediaPostsJob < ApplicationJob
  queue_as :default

  after_perform do
    Instagram::CreateMediaPostsJob.perform_later(@posts)
  end

  def perform
   #@posts = InstagramMedia.new.latest_media_posts
   @posts =[
    {
      "permalink": "https://www.instagram.com/p/Ce2GR3bBjsX/",
      "media_url": "https://scontent.cdninstagram.com/v/t51.2885-15/287754651_180014354457773_1196750841371863114_n.jpg?_nc_cat=100&ccb=1-7&_nc_sid=8ae9d6&_nc_eui2=AeE2JieLxRe0z9d9--CUPjr2NQuPj7lUdi41C4-PuVR2LmmsVX-AxzxZ6BzumOezZUo&_nc_ohc=ex2JyfB0poYAX-sqObN&_nc_ht=scontent.cdninstagram.com&edm=AM6HXa8EAAAA&oh=00_AT8ukE6LDLSz2CdWvsIwEnEYnw1eRp-3FTzB-N-rn2yViA&oe=62B0362D",
      "timestamp": "2022-06-16T00:01:13+0000",
      "id": "17923475462402481"
    },
    {
      "permalink": "https://www.instagram.com/p/CeuX3TIBl-E/",
      "media_url": "https://scontent.cdninstagram.com/v/t51.2885-15/287925179_501645578374355_1970947773552554122_n.jpg?_nc_cat=100&ccb=1-7&_nc_sid=8ae9d6&_nc_eui2=AeHl3HLKs6eDVgQA-Oeah2foupuNy0kyLIy6m43LSTIsjPOBVRXNKYSjrp5TTSI6fGU&_nc_ohc=xT66N2WwlDEAX-4VQNp&_nc_oc=AQlvCBnzX7yf55K_BWTMDEpk4ZAG5yTGrYik4PRwe_9CBk_xxVcQlrjqlJMfrePwV-8&_nc_ht=scontent.cdninstagram.com&edm=AM6HXa8EAAAA&oh=00_AT-_2vN-oy4GMGWw01_gKgk2y8cchzgGydtu3-E8TwFV4A&oe=62B0383A",
      "timestamp": "2022-06-13T00:00:55+0000",
      "id": "17944223338899496"
    },
    {
      "permalink": "https://www.instagram.com/p/CerzDj-MXD-/",
      "media_url": "https://scontent.cdninstagram.com/v/t51.2885-15/287227135_979324132732296_136649139624031528_n.jpg?_nc_cat=101&ccb=1-7&_nc_sid=8ae9d6&_nc_eui2=AeFXiT4TjtKHUSZfwh-vG5Yq4jdcSJe5WDLiN1xIl7lYMvv37GrLK3ncm7KHgfBjYfo&_nc_ohc=ainVgXO06wwAX8V0eCW&_nc_ht=scontent.cdninstagram.com&edm=AM6HXa8EAAAA&oh=00_AT-_5LHsNGpLkbG9V19TEVFQzjZbPaYiMRuaLXp01ZDUnw&oe=62AFB6C1",
      "timestamp": "2022-06-12T00:00:49+0000",
      "id": "17994047860472418"
    }]
  end
end
