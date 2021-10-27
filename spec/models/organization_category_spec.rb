# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrganizationCategory, type: :model do
  context 'OrganizationCategory model validation test' do
    subject { create(:organization_category) }

    it 'ensures organization_category can be created' do
      expect(subject).to be_valid
    end
  end
end