# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Service, type: :model do
  context 'Service model validation test' do
    subject { create(:service) }

    it 'ensures service can be created' do
      expect(subject).to be_valid
    end
  end
end