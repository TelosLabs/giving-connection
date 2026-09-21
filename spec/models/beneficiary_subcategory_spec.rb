require "rails_helper"

RSpec.describe BeneficiarySubcategory, type: :model do
  describe "associations" do
    subject { create(:beneficiary_subcategory) }

    it { is_expected.to belong_to(:beneficiary_group) }
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
      subcategory = create(:beneficiary_subcategory)
      expect(keys.map { |key| Rails.cache.read(key) }).to all(be_nil)

      keys.each { |key| Rails.cache.write(key, "stale") }
      subcategory.update!(name: "#{subcategory.name} renamed")
      expect(keys.map { |key| Rails.cache.read(key) }).to all(be_nil)

      keys.each { |key| Rails.cache.write(key, "stale") }
      subcategory.destroy!
      expect(keys.map { |key| Rails.cache.read(key) }).to all(be_nil)
    end
  end
end
