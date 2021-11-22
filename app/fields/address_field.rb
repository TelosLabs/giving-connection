# frozen_string_literal: true

require 'administrate/field/base'

class AddressField < Administrate::Field::Base
  def to_s
    data
  end
end

# app/fields/gravatar_field.rb
# require 'digest/md5'

# class GravatarField < Administrate::Field::Base
#   def gravatar_url
#     email_address = data.downcase
#     hash = Digest::MD5.hexdigest(email_address)
#     "http://www.gravatar.com/avatar/#{hash}"
#   end
# end
