# frozen_string_literal: true

# == Schema Information
#
# Table name: causes
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe Cause, type: :model do
  context 'Cause model validation test' do
    subject { create(:cause) }

    it 'ensures cause can be created' do
      expect(subject).to be_valid
    end
  end
end
