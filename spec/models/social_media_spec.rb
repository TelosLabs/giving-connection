require 'rails_helper'

RSpec.describe SocialMedia, type: :model do
  
  context 'Social Media model validation test' do

    subject { create(:social_media) }

    it 'ensures social media can be created' do
      expect(subject).to be_valid
    end
    
  end

end
