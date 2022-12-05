require 'rails_helper'

RSpec.describe AlertCause, type: :model do
  describe "associations" do
    subject { create(:alert_cause) }

    it { should belong_to(:alert) }
    it { should belong_to(:cause) }
  end
end
