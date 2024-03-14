require "rails_helper"

RSpec.describe Message, type: :model do
  describe "validations" do
    subject { create(:message) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to_not allow_value("invalid_email").for(:email) }
  end
end
