require 'rails_helper'

RSpec.describe OrganizationCause, type: :model do
  subject { build(:organization_cause) }

  describe "Associations" do
    it { should belong_to(:organization) }
    it { should belong_to(:cause) }
  end
end
