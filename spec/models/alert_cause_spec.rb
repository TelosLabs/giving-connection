require "rails_helper"

RSpec.describe AlertCause, type: :model do
  describe "associations" do
    subject { create(:alert_cause) }

    it { is_expected.to belong_to(:alert) }
    it { is_expected.to belong_to(:cause) }
  end
end
