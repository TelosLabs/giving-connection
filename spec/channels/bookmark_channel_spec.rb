require "rails_helper"

RSpec.describe BookmarkChannel, type: :channel do
  let(:user) { create(:user) }

  before do
    stub_connection current_user: user
  end

  describe "#subscribed" do
    it "subscribes to a stream when a user is created" do
      subscribe
      expect(subscription).to be_confirmed
    end
  end
end
