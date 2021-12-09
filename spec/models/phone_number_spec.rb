# == Schema Information
#
# Table name: phone_numbers
#
#  id          :bigint           not null, primary key
#  number      :string
#  main        :boolean
#  location_id :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe PhoneNumber, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
