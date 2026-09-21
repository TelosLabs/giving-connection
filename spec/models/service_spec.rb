# frozen_string_literal: true

# == Schema Information
#
# Table name: services
#
#  id         :bigint           not null, primary key
#  name       :string
#  cause_id   :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "rails_helper"

RSpec.describe Service, type: :model do
  describe "associations" do
    subject { create(:service) }

    it { is_expected.to belong_to(:cause) }
    it { is_expected.to have_many(:location_services).dependent(:destroy) }
    it { is_expected.to have_many(:locations).through(:location_services) }
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

    let(:keys) { %w[search_pills/services select_multiple/causes_with_services] }

    it "busts the search-pill caches on create, update, and destroy" do
      keys.each { |key| Rails.cache.write(key, "stale") }
      service = create(:service)
      expect(keys.map { |key| Rails.cache.read(key) }).to all(be_nil)

      keys.each { |key| Rails.cache.write(key, "stale") }
      service.update!(name: "#{service.name} renamed")
      expect(keys.map { |key| Rails.cache.read(key) }).to all(be_nil)

      keys.each { |key| Rails.cache.write(key, "stale") }
      service.destroy!
      expect(keys.map { |key| Rails.cache.read(key) }).to all(be_nil)
    end
  end
end
