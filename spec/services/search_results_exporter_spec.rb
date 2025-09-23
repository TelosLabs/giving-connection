# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchResultsExporter, type: :service do
  let(:organization) { create(:organization, scope_of_work: "National", verified: true) }
  let(:cause) { create(:cause, name: "Health") }
  let!(:location) do
    create(:location, :with_office_hours,
      name: "Test Nonprofit",
      address: "123 Main St, Nashville, TN 37201",
      email: "test@example.com",
      website: "https://example.com",
      organization: organization)
  end
  let!(:phone_number) { create(:phone_number, number: "555-123-4567", location: location) }

  before do
    organization.causes << cause
  end

  let(:search_results) { Location.where(id: location.id) }

  describe "#call" do
    subject { described_class.call(search_results) }

    it "generates CSV with proper headers" do
      csv_content = subject
      lines = csv_content.split("\n")

      expect(lines.first).to include("Nonprofit Name")
      expect(lines.first).to include("Description")
      expect(lines.first).to include("Address")
      expect(lines.first).to include("Phone Number")
      expect(lines.first).to include("Email")
      expect(lines.first).to include("Website")
      expect(lines.first).to include("Causes")
      expect(lines.first).to include("Verified")
      expect(lines.first).to include("Profile Link")
    end

    it "includes location data in CSV" do
      csv_content = subject
      lines = csv_content.split("\n")
      data_row = lines[1]

      expect(data_row).to include("Test Nonprofit")
      expect(data_row).to include("National")
      expect(data_row).to include("123 Main St, Nashville, TN 37201")
      expect(data_row).to include("555-123-4567")
      expect(data_row).to include("test@example.com")
      expect(data_row).to include("https://example.com")
      expect(data_row).to include("Health")
      expect(data_row).to include("Yes")
    end

    it "handles empty search results" do
      empty_results = Location.none
      csv_content = described_class.call(empty_results)
      lines = csv_content.split("\n")

      expect(lines.length).to eq(1) # Only headers
      expect(lines.first).to include("Nonprofit Name")
    end

    it "handles locations with nil organization" do
      location_without_org = create(:location, :with_office_hours, organization: nil)
      results = Location.where(id: location_without_org.id)

      expect { described_class.call(results) }.not_to raise_error

      csv_content = described_class.call(results)
      lines = csv_content.split("\n")
      expect(lines.length).to eq(2) # Headers + 1 data row
    end

    context "with address parsing" do
      let(:exporter) { described_class.new(search_results) }

      describe "#extract_city" do
        it "extracts city from full address" do
          city = exporter.send(:extract_city, "123 Main St, Nashville, TN 37201")
          expect(city).to eq("Nashville")
        end

        it "handles incomplete addresses" do
          city = exporter.send(:extract_city, "123 Main St")
          expect(city).to eq("")
        end

        it "handles nil address" do
          city = exporter.send(:extract_city, nil)
          expect(city).to eq("")
        end
      end

      describe "#extract_state" do
        it "extracts state from full address" do
          state = exporter.send(:extract_state, "123 Main St, Nashville, TN 37201")
          expect(state).to eq("TN")
        end

        it "handles address without zipcode" do
          state = exporter.send(:extract_state, "123 Main St, Nashville, TN")
          expect(state).to eq("TN")
        end
      end

      describe "#extract_zipcode" do
        it "extracts zipcode from full address" do
          zipcode = exporter.send(:extract_zipcode, "123 Main St, Nashville, TN 37201")
          expect(zipcode).to eq("37201")
        end

        it "handles address without zipcode" do
          zipcode = exporter.send(:extract_zipcode, "123 Main St, Nashville, TN")
          expect(zipcode).to eq("")
        end
      end
    end

    context "error handling" do
      it "raises error for nil search results" do
        expect { described_class.new(nil) }.to raise_error(ArgumentError, "Search results cannot be nil")
      end

      it "handles profile link generation errors" do
        allow(Rails.application.routes.url_helpers).to receive(:location_url).and_raise(StandardError)

        csv_content = subject
        lines = csv_content.split("\n")

        # Should still generate CSV, just with empty profile link
        expect(lines.length).to eq(2)
      end
    end
  end
end
