require 'rails_helper'

RSpec.describe OrganizationCause, type: :model do
  context 'OrganizationCause model validation test' do
    subject { create(:organization_cause) }

    it 'ensures organization_cause can be created' do
      expect(subject).to be_valid
    end
  end
end
