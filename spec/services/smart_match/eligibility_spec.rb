# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::Eligibility do
  def intent(user_type:, **answers)
    UserIntent.from_session(session_answers: answers, user_type: user_type)
  end

  # Mirrors the shape SimilarityQuery filters: an OrganizationEmbedding scope.
  def embedding_scope
    OrganizationEmbedding.all
  end

  def ids(scope)
    scope.pluck(:organization_id)
  end

  describe "required filters (never relaxed)" do
    it "keeps only organizations that offer services for the Find Help path" do
      offering = create(:organization)
      create(:organization_embedding, organization: offering)

      not_offering = create(:organization, name: "Admin Only Org", ein_number: "330011")
      not_offering.locations.each { |l| l.update_columns(offer_services: false) }
      create(:organization_embedding, organization: not_offering)

      scope = described_class.new(user_intent: intent(user_type: "service_seeker", causes: ["Health"]))
        .apply_required(embedding_scope)

      expect(ids(scope)).to include(offering.id)
      expect(ids(scope)).not_to include(not_offering.id)
    end

    # The agreed rule is "any location offers services", not "the main location
    # does". An org running programmes from a branch while head office is
    # administrative still offers services.
    it "accepts an organization whose branch offers services even if the main location does not" do
      org = create(:organization)
      org.locations.first.update_columns(offer_services: false, main: true)
      # :with_office_hours because LocationValidator requires office hours and
      # a time zone on any location that offers services.
      create(:location, :with_office_hours, organization: org, main: false, offer_services: true)
      create(:organization_embedding, organization: org)

      scope = described_class.new(user_intent: intent(user_type: "service_seeker", causes: ["Health"]))
        .apply_required(embedding_scope)

      expect(ids(scope)).to include(org.id)
    end

    it "does not apply the service-availability filter to donors or volunteers" do
      org = create(:organization)
      org.locations.each { |l| l.update_columns(offer_services: false) }
      create(:organization_embedding, organization: org)

      %w[donor volunteer].each do |user_type|
        scope = described_class.new(user_intent: intent(user_type: user_type, causes: ["Health"]))
          .apply_required(embedding_scope)

        expect(ids(scope)).to include(org.id), "#{user_type} should not be filtered on offer_services"
      end
    end
  end

  describe "relaxable filters" do
    it "requires volunteer capability on the volunteer path" do
      with_opps = create(:organization, volunteer_availability: true)
      create(:organization_embedding, organization: with_opps)
      without = create(:organization, name: "No Volunteering", ein_number: "330012", volunteer_availability: false)
      create(:organization_embedding, organization: without)

      eligibility = described_class.new(user_intent: intent(user_type: "volunteer", causes: ["Health"]))
      scope = eligibility.apply_relaxable(embedding_scope)

      expect(ids(scope)).to include(with_opps.id)
      expect(ids(scope)).not_to include(without.id)
      expect(eligibility.relaxable_labels).to eq([:volunteer_opportunities])
    end

    # volunteer_link is currently a strict subset of volunteer_availability in
    # production, so this OR adds nothing today -- but it keeps the filter
    # correct if an org ever gets a link without the flag.
    it "accepts a volunteer link even when the availability flag is unset" do
      org = create(:organization, volunteer_availability: false, volunteer_link: "https://example.org/volunteer")
      create(:organization_embedding, organization: org)

      scope = described_class.new(user_intent: intent(user_type: "volunteer", causes: ["Health"]))
        .apply_relaxable(embedding_scope)

      expect(ids(scope)).to include(org.id)
    end

    it "requires a donation link only when the donor asked for general donation" do
      with_link = create(:organization, donation_link: "https://example.org/give")
      create(:organization_embedding, organization: with_link)
      without = create(:organization, name: "No Donation Link", ein_number: "330013")
      create(:organization_embedding, organization: without)

      general = described_class.new(user_intent: intent(
        user_type: "donor", causes: ["Health"], donation_style: ["general_donation"]
      ))
      expect(ids(general.apply_relaxable(embedding_scope))).not_to include(without.id)
      expect(general.relaxable_labels).to eq([:donation_link])

      # Donating goods doesn't need a donation link.
      goods = described_class.new(user_intent: intent(
        user_type: "donor", causes: ["Health"], donation_style: ["goods_items"]
      ))
      expect(ids(goods.apply_relaxable(embedding_scope))).to include(without.id)
      expect(goods).not_to be_relaxable
    end

    it "has nothing to relax for a service seeker" do
      expect(described_class.new(user_intent: intent(user_type: "service_seeker", causes: ["Health"])))
        .not_to be_relaxable
    end

    # Closes the long-standing bug where "Remote services only" silently
    # applied a 100-mile physical radius. Relaxable rather than absolute
    # because the backing field ships empty -- see 06-phase-5-fields.md.
    describe "remote services only" do
      def remote_seeker
        intent(user_type: "service_seeker", causes: ["Health"],
          travel_bucket: SmartMatch::Eligibility::REMOTE_ONLY_TRAVEL_BUCKET)
      end

      it "keeps only organizations with a remote-capable location" do
        remote = create(:organization, name: "Remote Org", ein_number: "550011")
        remote.locations.first.update_columns(remote_services: true)
        create(:organization_embedding, organization: remote)

        in_person = create(:organization, name: "In Person Org", ein_number: "550012")
        create(:organization_embedding, organization: in_person)

        eligibility = described_class.new(user_intent: remote_seeker)
        scope = eligibility.apply_relaxable(embedding_scope)

        expect(ids(scope)).to include(remote.id)
        expect(ids(scope)).not_to include(in_person.id)
        expect(eligibility.relaxable_labels).to include(:remote_services)
      end

      it "does not filter on remote services for any other travel answer" do
        %w[nearby moderate far].each do |bucket|
          eligibility = described_class.new(
            user_intent: intent(user_type: "service_seeker", causes: ["Health"], travel_bucket: bucket)
          )
          expect(eligibility.relaxable_labels).not_to include(:remote_services),
            "travel bucket #{bucket} should not imply remote-only"
        end
      end
    end
  end

  # Every relaxable filter can end up named in the "we broadened your search"
  # notice. A label with no translation renders a raw missing-translation
  # string to the user, so the two must stay in step.
  describe "broadened-search labels" do
    # Every label any path can produce.
    let(:all_labels) do
      [
        intent(user_type: "volunteer", causes: ["Health"]),
        intent(user_type: "donor", causes: ["Health"], donation_style: ["general_donation"]),
        intent(user_type: "service_seeker", causes: ["Health"],
          travel_bucket: SmartMatch::Eligibility::REMOTE_ONLY_TRAVEL_BUCKET)
      ].flat_map { |i| described_class.new(user_intent: i).relaxable_labels }.uniq
    end

    it "covers every relaxable filter in both locales" do
      expect(all_labels).to contain_exactly(:volunteer_opportunities, :donation_link, :remote_services)

      %i[en es].each do |locale|
        all_labels.each do |label|
          translation = I18n.t("smart_match.results.broadened.filters.#{label}",
            locale: locale, default: nil)
          expect(translation).to be_present,
            "missing #{locale} translation for broadened filter #{label}"
        end
      end
    end
  end

  describe "preference answers are never filters" do
    # Selecting more causes must widen what can rank highly, not narrow the
    # pool -- an org matching one of four selected causes is still eligible.
    it "does not exclude organizations that match only some selected causes" do
      org = create(:organization)
      create(:organization_embedding, organization: org)

      eligibility = described_class.new(user_intent: intent(
        user_type: "service_seeker",
        causes: ["Health", "Mental Health", "Seniors", "Education"],
        self_description: %w[senior veteran],
        prefs: %w[wheelchair_accessible multilingual]
      ))

      scope = eligibility.apply_relaxable(eligibility.apply_required(embedding_scope))

      expect(ids(scope)).to include(org.id)
    end
  end
end
