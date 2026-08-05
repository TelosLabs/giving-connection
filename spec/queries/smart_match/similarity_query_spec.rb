# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::SimilarityQuery do
  let(:embedding) { Array.new(1024) { rand(-1.0..1.0) } }
  let(:coordinates) { {latitude: 36.1627, longitude: -86.7816} }

  # SimilarityQuery returns a Result (candidates + the eligibility filters it
  # had to drop), so specs reach through to the candidate list.
  def org_ids(result)
    result.candidates.map { |c| c[:organization_embedding].organization_id }
  end

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

      expect(results.candidates).to be_an(Array)
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

      expect(results.candidates).to be_an(Array)
      result = results.candidates.first
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

      expect(results.candidates).to be_an(Array)
    end

    describe "location scope (nationwide / international)" do
      def ids(results)
        org_ids(results)
      end

      it "matches National orgs for a nationwide search, ignoring state/coordinates" do
        national = create(:organization, scope_of_work: "National")
        national.locations.first.update_columns(state_code: "CA")
        create(:organization_embedding, organization: national)

        results = described_class.call(
          embedding: embedding, state: nil, coordinates: nil, location_scope: "national"
        )

        expect(ids(results)).to include(national.id)
      end

      it "excludes Regional orgs from a nationwide search" do
        regional = create(:organization, scope_of_work: "Regional")
        create(:organization_embedding, organization: regional)

        results = described_class.call(
          embedding: embedding, state: nil, coordinates: nil, location_scope: "national"
        )

        expect(ids(results)).not_to include(regional.id)
      end

      it "broadens a nationwide search to International when no National orgs exist" do
        intl = create(:organization, scope_of_work: "International")
        create(:organization_embedding, organization: intl)

        results = described_class.call(
          embedding: embedding, state: nil, coordinates: nil, location_scope: "national"
        )

        expect(ids(results)).to include(intl.id)
      end

      it "matches only International orgs for an international search" do
        intl = create(:organization, scope_of_work: "International")
        create(:organization_embedding, organization: intl)
        national = create(:organization, name: "National Org", scope_of_work: "National")
        create(:organization_embedding, organization: national)

        results = described_class.call(
          embedding: embedding, state: nil, coordinates: nil, location_scope: "international"
        )

        expect(ids(results)).to include(intl.id)
        expect(ids(results)).not_to include(national.id)
      end
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

        expect(org_ids(results)).to include(org.id)
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

        matched = org_ids(results)
        expect(matched).to include(tn_org.id)
        expect(matched).not_to include(me_org.id)
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

        expect(org_ids(results)).to include(org.id)
      end
    end

    # Before this, a National organization with no location in the searched
    # state was invisible to a local searcher -- the state predicate dropped
    # it, and every radius pass would have dropped it again. The client's
    # scoring spec calls for them on every location row.
    describe "nationwide organizations in a local search" do
      def tn_anchor
        org = create(:organization, name: "Tennessee Anchor", ein_number: "440001", scope_of_work: "Regional")
        org.locations.first.update_columns(address: "1 Main St, Nashville, TN", state_code: "TN",
          lonlat: Geo.point(-86.7816, 36.1627), latitude: 36.1627, longitude: -86.7816)
        create(:organization_embedding, organization: org)
        org
      end

      it "includes a National org that has no location in the searched state" do
        tn_anchor
        national = create(:organization, name: "National Helpline", ein_number: "440002", scope_of_work: "National")
        national.locations.first.update_columns(address: "9 Ocean Ave, Los Angeles, CA", state_code: "CA")
        create(:organization_embedding, organization: national)

        results = described_class.call(
          embedding: embedding, state: "TN", coordinates: coordinates, radius_miles: 5
        )

        expect(org_ids(results)).to include(national.id)
      end

      it "keeps the National org through radius narrowing despite being far away" do
        tn_anchor
        national = create(:organization, name: "Distant National", ein_number: "440003", scope_of_work: "National")
        national.locations.first.update_columns(
          address: "9 Ocean Ave, Los Angeles, CA", state_code: "CA",
          lonlat: Geo.point(-118.2437, 34.0522), latitude: 34.0522, longitude: -118.2437
        )
        create(:organization_embedding, organization: national)

        results = described_class.call(
          embedding: embedding, state: "TN", coordinates: coordinates, radius_miles: 5
        )

        expect(org_ids(results)).to include(national.id)
      end

      # Regression: including nationwide orgs in local searches (Phase 3)
      # introduced a penalty for them. distance_miles was computed from their
      # head office, so a national org headquartered 1,800 miles away scored
      # 0 on the distance term -- punished for the exact property that made it
      # eligible. nil means "distance does not apply here", which is already
      # how Scorer#distance_score reads it.
      # Enough in-radius organizations that the coordinate-bearing branch of
      # the radius expansion is used. With fewer than min_results the query
      # falls back to the state-wide pass, which reports no distance for
      # anyone and would make these assertions pass for the wrong reason.
      def nashville_cluster
        3.times.map do |i|
          org = create(:organization, name: "Nashville Org #{i}", ein_number: "4405#{i}", scope_of_work: "Regional")
          org.locations.first.update_columns(
            address: "#{i} Main St, Nashville, TN", state_code: "TN",
            lonlat: Geo.point(-86.7816, 36.1627), latitude: 36.1627, longitude: -86.7816
          )
          create(:organization_embedding, organization: org)
          org
        end
      end

      def distant_national
        org = create(:organization, name: "Coast To Coast", ein_number: "440059", scope_of_work: "National")
        org.locations.first.update_columns(
          address: "9 Ocean Ave, Los Angeles, CA", state_code: "CA",
          lonlat: Geo.point(-118.2437, 34.0522), latitude: 34.0522, longitude: -118.2437
        )
        create(:organization_embedding, organization: org)
        org
      end

      it "reports no distance for a nationwide org so it is not penalised for being far" do
        nashville_cluster
        national = distant_national

        results = described_class.call(
          embedding: embedding, state: "TN", coordinates: coordinates, radius_miles: 5
        )

        candidate = results.candidates.find { |c| c[:organization_embedding].organization_id == national.id }
        expect(candidate).to be_present, "the nationwide org should be a candidate at all"
        expect(candidate[:distance_miles]).to be_nil
      end

      it "still measures distance for a Regional org in the searched state" do
        local = nashville_cluster.first
        distant_national

        results = described_class.call(
          embedding: embedding, state: "TN", coordinates: coordinates, radius_miles: 5
        )

        candidate = results.candidates.find { |c| c[:organization_embedding].organization_id == local.id }
        expect(candidate[:distance_miles]).to be_within(1).of(0)
      end

      it "still excludes an out-of-state Regional org" do
        tn_anchor
        regional = create(:organization, name: "California Only", ein_number: "440004", scope_of_work: "Regional")
        regional.locations.first.update_columns(address: "9 Ocean Ave, Los Angeles, CA", state_code: "CA")
        create(:organization_embedding, organization: regional)

        results = described_class.call(
          embedding: embedding, state: "TN", coordinates: coordinates, radius_miles: 5
        )

        expect(org_ids(results)).not_to include(regional.id)
      end
    end

    # The client's spec gives the donor "Anywhere" answer "All nonprofits" and
    # "No geographic weight". The answer was being stored and then ignored, so
    # a donor who said Anywhere was still hard-filtered to whichever single
    # state their next answer implied -- the opposite of what they asked for.
    describe "donors who chose Anywhere" do
      def donor_intent(impact_location)
        UserIntent.from_session(
          session_answers: {
            state: "TN", city: "Nashville", location_scope: "local",
            causes: ["Health"], impact_location: impact_location
          },
          user_type: "donor"
        )
      end

      def org_in(name, ein, state_code, address)
        org = create(:organization, name: name, ein_number: ein, scope_of_work: "Regional")
        org.locations.first.update_columns(address: address, state_code: state_code)
        create(:organization_embedding, organization: org)
        org
      end

      it "ignores geography entirely" do
        tn = org_in("TN Org", "45001", "TN", "1 Main St, Nashville, TN")
        ca = org_in("CA Org", "45002", "CA", "9 Ocean Ave, Los Angeles, CA")

        results = described_class.call(
          embedding: embedding, state: "TN", coordinates: coordinates,
          radius_miles: 5, user_intent: donor_intent("anywhere")
        )

        expect(org_ids(results)).to include(tn.id, ca.id)
      end

      it "still filters by state for a donor who named a place" do
        tn = org_in("TN Org", "45003", "TN", "1 Main St, Nashville, TN")
        ca = org_in("CA Org", "45004", "CA", "9 Ocean Ave, Los Angeles, CA")

        results = described_class.call(
          embedding: embedding, state: "TN", coordinates: coordinates,
          radius_miles: 5, user_intent: donor_intent("specific_place")
        )

        expect(org_ids(results)).to include(tn.id)
        expect(org_ids(results)).not_to include(ca.id)
      end

      it "does not let a service seeker opt out of geography" do
        tn = org_in("TN Org", "45005", "TN", "1 Main St, Nashville, TN")
        ca = org_in("CA Org", "45006", "CA", "9 Ocean Ave, Los Angeles, CA")

        seeker = UserIntent.from_session(
          session_answers: {state: "TN", city: "Nashville", causes: ["Health"], impact_location: "anywhere"},
          user_type: "service_seeker"
        )

        results = described_class.call(
          embedding: embedding, state: "TN", coordinates: coordinates,
          radius_miles: 5, user_intent: seeker
        )

        expect(org_ids(results)).to include(tn.id)
        expect(org_ids(results)).not_to include(ca.id)
      end
    end

    # Distance used to be measured from main_location only, which contradicted
    # the eligibility filters ("any location offers services") and made an
    # organization with a nearby branch look as far away as its head office.
    describe "distance across multiple locations" do
      def anchor_cluster
        3.times.map do |i|
          org = create(:organization, name: "Anchor #{i}", ein_number: "9910#{i}", scope_of_work: "Regional")
          org.locations.first.update_columns(
            address: "#{i} Main St, Nashville, TN", state_code: "TN",
            lonlat: Geo.point(-86.7816, 36.1627), latitude: 36.1627, longitude: -86.7816
          )
          create(:organization_embedding, organization: org)
          org
        end
      end

      def distance_for(results, org)
        results.candidates
          .find { |c| c[:organization_embedding].organization_id == org.id }
          &.dig(:distance_miles)
      end

      def search
        described_class.call(embedding: embedding, state: "TN", coordinates: coordinates, radius_miles: 50)
      end

      it "measures from the nearest location, not the main one" do
        anchor_cluster
        org = create(:organization, name: "Branch Org", ein_number: "99200", scope_of_work: "Regional")
        # Head office far east of Nashville...
        org.locations.first.update_columns(
          address: "1 Far Rd, Knoxville, TN", state_code: "TN", main: true,
          lonlat: Geo.point(-83.9207, 35.9606), latitude: 35.9606, longitude: -83.9207
        )
        # ...branch right on top of the user.
        create(:location, :with_office_hours, organization: org, main: false, offer_services: true,
          address: "2 Near St, Nashville, TN", state_code: "TN",
          lonlat: Geo.point(-86.7816, 36.1627), latitude: 36.1627, longitude: -86.7816)
        create(:organization_embedding, organization: org)

        expect(distance_for(search, org.reload)).to be_within(1).of(0)
      end

      # A PO box geocodes to a post office: roughly right for the town, wrong
      # for a five-mile radius. nil is the neutral "distance doesn't apply".
      it "ignores PO box locations when measuring" do
        anchor_cluster
        org = create(:organization, name: "PO Box Only", ein_number: "99300", scope_of_work: "Regional")
        org.locations.first.update_columns(
          address: "PO Box 5, Nashville, TN", state_code: "TN", po_box: true,
          lonlat: Geo.point(-86.7816, 36.1627), latitude: 36.1627, longitude: -86.7816
        )
        create(:organization_embedding, organization: org)

        expect(distance_for(search, org.reload)).to be_nil
      end

      it "still measures a physical location when the organization also has a PO box" do
        anchor_cluster
        org = create(:organization, name: "Box And Office", ein_number: "99400", scope_of_work: "Regional")
        org.locations.first.update_columns(
          address: "PO Box 9, Nashville, TN", state_code: "TN", po_box: true,
          lonlat: Geo.point(-83.9207, 35.9606), latitude: 35.9606, longitude: -83.9207
        )
        create(:location, :with_office_hours, organization: org, main: false, offer_services: true,
          address: "3 Real St, Nashville, TN", state_code: "TN",
          lonlat: Geo.point(-86.7816, 36.1627), latitude: 36.1627, longitude: -86.7816)
        create(:organization_embedding, organization: org)

        expect(distance_for(search, org.reload)).to be_within(1).of(0)
      end
    end

    describe "eligibility filters and relaxation" do
      def volunteer_intent
        UserIntent.from_session(
          session_answers: {state: "TN", city: "Nashville", causes: ["Health"]},
          user_type: "volunteer"
        )
      end

      def nashville_org(name, ein, **attrs)
        org = create(:organization, name: name, ein_number: ein, scope_of_work: "Regional", **attrs)
        org.locations.first.update_columns(
          address: "1 Main St, Nashville, TN", state_code: "TN",
          lonlat: Geo.point(-86.7816, 36.1627), latitude: 36.1627, longitude: -86.7816
        )
        create(:organization_embedding, organization: org)
        org
      end

      it "applies the volunteer filter when enough organizations satisfy it" do
        3.times { |i| nashville_org("Volunteering Org #{i}", "4410#{i}", volunteer_availability: true) }
        no_opps = nashville_org("No Volunteering", "44199", volunteer_availability: false)

        results = described_class.call(
          embedding: embedding, state: "TN", coordinates: coordinates,
          radius_miles: 5, user_intent: volunteer_intent
        )

        expect(org_ids(results)).not_to include(no_opps.id)
        expect(results.relaxed).to be_empty
        expect(results).not_to be_relaxed
      end

      # The alternative is an empty page for someone willing to help. Showing
      # the closest organizations is better, provided we say what we dropped.
      it "drops the volunteer filter and reports it when too few organizations qualify" do
        no_opps = nashville_org("No Volunteering", "44200", volunteer_availability: false)

        results = described_class.call(
          embedding: embedding, state: "TN", coordinates: coordinates,
          radius_miles: 5, user_intent: volunteer_intent
        )

        expect(org_ids(results)).to include(no_opps.id)
        expect(results.relaxed).to eq([:volunteer_opportunities])
        expect(results).to be_relaxed
      end

      it "never relaxes the service-availability requirement" do
        # Enough service-offering orgs would exist only by relaxing; there are
        # none, so the result is empty rather than filled with ineligible orgs.
        admin_only = nashville_org("Admin Only", "44300")
        admin_only.locations.each { |l| l.update_columns(offer_services: false) }

        seeker = UserIntent.from_session(
          session_answers: {state: "TN", city: "Nashville", causes: ["Health"]},
          user_type: "service_seeker"
        )

        results = described_class.call(
          embedding: embedding, state: "TN", coordinates: coordinates,
          radius_miles: 5, user_intent: seeker
        )

        expect(org_ids(results)).not_to include(admin_only.id)
      end

      it "reports no relaxation when there is nothing relaxable to drop" do
        nashville_org("Service Org", "44400")

        seeker = UserIntent.from_session(
          session_answers: {state: "TN", city: "Nashville", causes: ["Health"]},
          user_type: "service_seeker"
        )

        results = described_class.call(
          embedding: embedding, state: "TN", coordinates: coordinates,
          radius_miles: 5, user_intent: seeker
        )

        expect(results.relaxed).to be_empty
      end
    end
  end
end
