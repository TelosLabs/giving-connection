# frozen_string_literal: true

# == Schema Information
#
# Table name: organization_admins
#
#  id              :bigint           not null, primary key
#  organization_id :bigint           not null
#  user_id         :bigint           not null
#  role            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
require 'rails_helper'

RSpec.describe OrganizationAdmin, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
