# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Organization, type: :model do
  context 'Organization model validation test' do
    subject { create(:organization) }

    it 'ensures organizations can be created' do
      expect(subject).to be_valid
    end

    it 'attaches a default logo'do
      expect(subject.logo.attached?).to eq(true)
    end

    it 'attaches a default cover photo'do
      expect(subject.cover_photo.attached?).to eq(true)
    end
  end
end
