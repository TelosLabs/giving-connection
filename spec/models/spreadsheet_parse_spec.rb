require "rails_helper"
require "rake"

RSpec.describe SpreadsheetParse do
  describe "#csv_file_paths" do
    let!(:spreadsheet) { "#{fixture_path}/GC_Dummy_Data_for_DB.xlsx" }
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
    before do
      Rails.application.load_tasks
      Rake::Task["populate:seed_causes_and_services"].invoke
      Rake::Task["populate:seed_beneficiaries_and_beneficiaries_subcategories"].invoke
    end

    let!(:spreadsheet) { "#{fixture_path}/GC_Dummy_Data_for_DB.xlsx" }
    let!(:creator) { create(:admin_user) }

    it "builds organizations" do
      parser = described_class.new(spreadsheet, creator)

      expect { parser.create_models }.to change { Organization.count }.by(45)
    end
  end

  describe "#import" do
    let!(:creator) { create(:admin_user) }
    let(:spreadsheet) { "#{fixture_path}/GC_Dummy_Data_for_DB.xlsx" }

    before do
      Rails.application.load_tasks
      Rake::Task["populate:seed_causes_and_services"].invoke
      Rake::Task["populate:seed_beneficiaries_and_beneficiaries_subcategories"].invoke
    end

    it "creates organizations" do
      expect { described_class.new(spreadsheet, creator).import }.to change { Organization.count }
      expect(Organization.first.locations.count).to be > 0
    end
  end
end
