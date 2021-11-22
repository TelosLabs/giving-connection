# frozen_string_literal: true

# == Schema Information
#
# Table name: organization_categories
#
#  id              :bigint           not null, primary key
#  organization_id :bigint           not null
#  category_id     :bigint           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
require 'rails_helper'

RSpec.describe OrganizationCategory, type: :model do
  context 'OrganizationCategory model validation test' do
    subject { create(:organization_category) }

    it 'ensures organization_category can be created' do
      expect(subject).to be_valid
    end
  end
end
