# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Organization, type: :model do
  context 'Organization model validation test' do
    subject { create(:organization) }

    it 'ensures organizations can be created' do
      expect(subject).to be_valid
    end
  end
end
