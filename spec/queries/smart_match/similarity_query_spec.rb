# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::SimilarityQuery do
  let(:embedding) { Array.new(1024) { rand(-1.0..1.0) } }
  let(:coordinates) { {latitude: 36.1627, longitude: -86.7816} }

  describe ".call" do
    it "returns results filtered by state" do
      org = create(:organization)
      loc = org.locations.first
      loc.update_columns(address: "123 Main St, Nashville, TN 37201")
      create(:organization_embedding, organization: org)

      results = described_class.call(
        embedding: embedding,
        state: "TN",
        coordinates: coordinates,
        radius_miles: 50
      )

      expect(results).to be_an(Array)
    end

    it "returns results with expected keys" do
      org = create(:organization)
      loc = org.locations.first
      loc.update_columns(address: "123 Main St, Nashville, TN 37201")
      create(:organization_embedding, organization: org)

      results = described_class.call(
        embedding: embedding,
        state: "TN",
        coordinates: coordinates,
        radius_miles: 50
      )

      expect(results).to be_an(Array)
      result = results.first
      expect(result).to include(:organization_embedding, :cosine_distance, :distance_miles)
    end

    it "falls back to state-wide results when no nearby results" do
      org = create(:organization)
      loc = org.locations.first
      loc.update_columns(address: "123 Main St, Nashville, TN 37201")
      create(:organization_embedding, organization: org)

      far_coordinates = {latitude: 0.0, longitude: 0.0}

      results = described_class.call(
        embedding: embedding,
        state: "TN",
        coordinates: far_coordinates,
        radius_miles: 5
      )

      expect(results).to be_an(Array)
    end

    # Correctness sentinel: the ILIKE fallback matches false positives like
    # "Patten, ME" being matched as TN. When a location has the structured
    # state_code column populated, we MUST use that exact-match column even
    # if the address text happens to also contain the queried state's letters.
    describe "state filter precedence" do
      it "matches a TN location when state_code is set to TN" do
        org = create(:organization)
        loc = org.locations.first
        loc.update_columns(address: "123 Main St, Nashville", state_code: "TN")
        create(:organization_embedding, organization: org)

        results = described_class.call(
          embedding: embedding,
          state: "TN",
          coordinates: coordinates,
          radius_miles: 50
        )

        expect(results.map { |r| r[:organization_embedding].organization_id }).to include(org.id)
      end

      it "does NOT match a ME location even when its address text contains 'TN' (Patten case)" do
        # Seed a TN org so state_scope.none? is false and the nationwide
        # fallback (which would let ME slip in) is not triggered.
        tn_org = create(:organization, name: "Tennessee Org")
        tn_org.locations.first.update_columns(address: "1 Main St, Nashville, TN", state_code: "TN")
        create(:organization_embedding, organization: tn_org)

        me_org = create(:organization, name: "Maine Org")
        me_org.locations.first.update_columns(address: "1 Patten Ave, Patten, ME 04765", state_code: "ME")
        create(:organization_embedding, organization: me_org)

        results = described_class.call(
          embedding: embedding,
          state: "TN",
          coordinates: coordinates,
          radius_miles: 50
        )

        org_ids = results.map { |r| r[:organization_embedding].organization_id }
        expect(org_ids).to include(tn_org.id)
        expect(org_ids).not_to include(me_org.id)
      end

      it "still uses ILIKE fallback for rows where state_code is NULL (not yet backfilled)" do
        org = create(:organization)
        loc = org.locations.first
        loc.update_columns(address: "123 Main St, Nashville, TN 37201", state_code: nil)
        create(:organization_embedding, organization: org)

        results = described_class.call(
          embedding: embedding,
          state: "TN",
          coordinates: coordinates,
          radius_miles: 50
        )

        expect(results.map { |r| r[:organization_embedding].organization_id }).to include(org.id)
      end
    end
  end
end
