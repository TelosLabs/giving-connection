# frozen_string_literal: true

# == Schema Information
#
# Table name: beneficiary_groups
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "rails_helper"

RSpec.describe BeneficiaryGroup, type: :model do
  describe "associations" do
    subject { create(:beneficiary_group) }

    it { is_expected.to have_many(:beneficiary_subcategories).dependent(:destroy) }
  end

  # SearchesController and SelectMultiple::Component cache these lookups for a
  # day; this pins that a write actually busts them instead of leaving up to a day of staleness after an edit.
  # Test environment uses :null_store, which would make this a no-op false positive, so a real store
  # is swapped in just for this example.
  describe "cache invalidation" do
    around do |example|
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      example.run
      Rails.cache = original_cache
    end

    let(:keys) { %w[search_pills/beneficiary_groups select_multiple/beneficiary_groups_with_subcategories] }

    it "busts the search-pill caches on create, update, and destroy" do
      keys.each { |key| Rails.cache.write(key, "stale") }
      group = create(:beneficiary_group)
      expect(keys.map { |key| Rails.cache.read(key) }).to all(be_nil)

      keys.each { |key| Rails.cache.write(key, "stale") }
      group.update!(name: "#{group.name} renamed")
      expect(keys.map { |key| Rails.cache.read(key) }).to all(be_nil)

      keys.each { |key| Rails.cache.write(key, "stale") }
      group.destroy!
      expect(keys.map { |key| Rails.cache.read(key) }).to all(be_nil)
    end
  end
end
