require 'rails_helper'

RSpec.describe Message, type: :model do
  describe "validations" do
    subject { create(:message) }

    it {should validate_presence_of(:name) }
    it {should validate_presence_of(:email) }
  end
end
