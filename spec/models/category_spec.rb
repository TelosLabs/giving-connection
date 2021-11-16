# frozen_string_literal: true

# == Schema Information
#
# Table name: categories
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe Category, type: :model do
  context 'Category model validation test' do
    subject { create(:category) }

    it 'ensures category can be created' do
      expect(subject).to be_valid
    end
  end
end
