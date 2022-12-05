require 'rails_helper'

RSpec.describe InstagramPost, type: :model do
    describe "validations" do
        subject { create(:instagram_post) }

        it { should validate_presence_of(:external_id) }
        it { should validate_presence_of(:post_url) }
        it { should validate_presence_of(:media_url) }
        it { should validate_presence_of(:media_type) }
        it { should validate_presence_of(:creation_date) }
    end

    describe "scopes" do
        before do
            10.times { create( :instagram_post ) }
        end
        
        it "should return the six latest posts" do
            expect(InstagramPost.latest_six_created.length).to be(6)
            expect(InstagramPost.latest_six_created[0].creation_date > InstagramPost.latest_six_created[1].creation_date).to be(true)
            expect(InstagramPost.latest_six_created[1].creation_date > InstagramPost.latest_six_created[2].creation_date).to be(true)
            expect(InstagramPost.latest_six_created[2].creation_date > InstagramPost.latest_six_created[3].creation_date).to be(true)
            expect(InstagramPost.latest_six_created[3].creation_date > InstagramPost.latest_six_created[4].creation_date).to be(true)
            expect(InstagramPost.latest_six_created[4].creation_date > InstagramPost.latest_six_created[5].creation_date).to be(true)
        end
    end
end
