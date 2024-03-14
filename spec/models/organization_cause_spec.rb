require "rails_helper"

RSpec.describe OrganizationCause, type: :model do
  subject { build(:organization_cause) }

  describe "Associations" do
    it { is_expected.to belong_to(:organization) }
    it { is_expected.to belong_to(:cause) }
  end
end
