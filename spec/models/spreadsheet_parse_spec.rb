require "rails_helper"
require "rake"

RSpec.describe SpreadsheetParse do
  xdescribe "#csv_file_paths" do
    let(:spreadsheet) { "#{fixture_path}/GC_Dummy_Data_for_DB.xlsx" }
    let(:file_path) { File.open(Rails.root.join("db/uploads").to_s) }

    it "returns a hash of csv paths" do
      csv_paths = described_class.new.csv_file_paths(spreadsheet, file_path)

      expect(csv_paths).to be_a(Hash)
      expect(csv_paths[:orgs_csv_file]).to eq("#{file_path.path}/orgs.csv")
    end
  end

  xdescribe "#create_models" do
    before do
      Rails.application.load_tasks
      Rake::Task["populate:seed_causes_and_services"].invoke
      Rake::Task["populate:seed_beneficiaries_and_beneficiaries_subcategories"].invoke
    end

    let(:spreadsheet) { "#{fixture_path}/GC_Dummy_Data_for_DB.xlsx" }
    let(:file_path) { File.open(Rails.root.join("db/uploads").to_s) }
    let(:csv_file_paths) { described_class.new.csv_file_paths(spreadsheet, file_path) }

    it "builds organizations" do
      expect { described_class.new.create_models(csv_file_paths) }.to change { Organization.count }.by(1)
    end
  end

  xdescribe "#import" do
    before do
      create(:admin_user)
      Rails.application.load_tasks
      Rake::Task["populate:seed_causes_and_services"].invoke
      Rake::Task["populate:seed_beneficiaries_and_beneficiaries_subcategories"].invoke
    end

    let(:spreadsheet) { "#{fixture_path}/GC_Dummy_Data_for_DB.xlsx" }

    it "creates organizations" do
      expect { described_class.new.import(spreadsheet) }.to change { Organization.count }
      expect(Organization.first).to be_a(Organization)
      expect(Organization.first.locations.count).to be > 0
    end
  end
end
