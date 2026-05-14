# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrganizationEmbedding, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:organization) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:embedding) }
    it { is_expected.to validate_presence_of(:text_snapshot) }
  end

end
