require "rails_helper"
require "rake"

RSpec.describe SpreadsheetParse do
  describe "#csv_file_paths" do
    let!(:spreadsheet) { "#{fixture_paths.first}/GC_Dummy_Data_for_DB.xlsx" }
    let!(:creator) { create(:admin_user) }
    let(:file_path) { File.open(Rails.root.join("db/uploads").to_s) }

    it "returns a hash of csv paths" do
      parser = described_class.new(spreadsheet, creator)
      csv_paths = parser.csv_file_paths

      expect(csv_paths).to be_a(Hash)
      expect(csv_paths[:orgs_csv_file]).to eq("#{file_path.path}/orgs.csv")
    end
  end

  describe "#create_models" do
    let!(:spreadsheet) { "#{fixture_paths.first}/GC_Dummy_Data_for_DB.xlsx" }
    let!(:creator) { create(:admin_user) }

    it "builds organizations" do
      parser = described_class.new(spreadsheet, creator)
      orgs = parser.create_models

      expect(orgs).to be_an(Array)
      expect(orgs.first).to be_a(Organization)
    end
  end

  describe "#import" do
    let!(:creator) { create(:admin_user) }
    let!(:spreadsheet) { "#{fixture_paths.first}/GC_Dummy_Data_for_DB.xlsx" }

    it "returns a hash of import results" do
      results = described_class.new(spreadsheet, creator).import

      expect(results).to be_a(Hash)
      expect(results[:ids]).to be_an(Array)
      expect(results[:failed_instances]).to be_an(Array)
    end
  end
end
