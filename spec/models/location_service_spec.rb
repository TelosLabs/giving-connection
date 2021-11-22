# frozen_string_literal: true

# == Schema Information
#
# Table name: location_services
#
#  id          :bigint           not null, primary key
#  description :string
#  location_id :bigint           not null
#  service_id  :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe LocationService, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
