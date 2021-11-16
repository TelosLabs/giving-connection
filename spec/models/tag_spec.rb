# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tag, type: :model do
  context 'Tag model validation test' do
    subject { create(:tag) }

    it 'ensures tags can be created' do
      expect(subject).to be_valid
    end
  end
end
