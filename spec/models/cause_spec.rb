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
require "rails_helper"

RSpec.describe Cause, type: :model do
  describe "associations" do
    subject { create(:cause) }

    it { is_expected.to have_many(:organization_causes).dependent(:destroy) }
    it { is_expected.to have_many(:organizations).through(:organization_causes) }
    it { is_expected.to have_many(:services) }
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

    let(:keys) { %w[search_pills/causes search_pills/services select_multiple/causes_with_services] }

    it "busts the search-pill caches on create, update, and destroy" do
      keys.each { |key| Rails.cache.write(key, "stale") }
      cause = create(:cause)
      expect(keys.map { |key| Rails.cache.read(key) }).to all(be_nil)

      keys.each { |key| Rails.cache.write(key, "stale") }
      cause.update!(name: "#{cause.name} renamed")
      expect(keys.map { |key| Rails.cache.read(key) }).to all(be_nil)

      keys.each { |key| Rails.cache.write(key, "stale") }
      cause.destroy!
      expect(keys.map { |key| Rails.cache.read(key) }).to all(be_nil)
    end
  end
end
