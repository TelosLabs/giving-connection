require "rails_helper"

RSpec.describe AlertService, type: :model do
  context "AlertService model validation test" do
    subject { create(:alert_service) }

    it "ensures alert_service can be created" do
      expect(subject).to be_valid
    end
  end
end
