# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Category, type: :model do
  context 'Category model validation test' do
    subject { create(:category) }

    it 'ensures category can be created' do
      expect(subject).to be_valid
    end
  end
end
