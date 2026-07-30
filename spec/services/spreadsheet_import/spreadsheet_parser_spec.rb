require "rails_helper"

RSpec.describe SpreadsheetImport::SpreadsheetParser do
  let(:admin) { create(:admin_user) }
  let(:cause) { create(:cause) }
  let(:headers) do
    [
      "Organization Name", "EIN Number", "IRS NTEE Code", "Scope of Work",
      "Mission Statement - What We Do", "Vision - Goals and Aspirations",
      "Services - How We Do It", "Website link", "Donation link", "Email", "Phone",
      "Address", "Hours of Operation", "Detailed Hours Of Operation", "Causes"
    ]
  end

  # The importer only reads the "orgs" sheet, so a one-row workbook is enough.
  def spreadsheet_for(row)
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: "orgs") do |sheet|
      sheet.add_row headers
      sheet.add_row headers.map { |header| row[header] }
    end

    file = Tempfile.new(["orgs", ".xlsx"])
    package.serialize(file.path)
    file
  end

  def org_row(overrides = {})
    {
      "Organization Name" => "Asteme Learning Center Inc",
      "EIN Number" => "12-3456789",
      "IRS NTEE Code" => "A01",
      "Scope of Work" => "Regional",
      "Mission Statement - What We Do" => "Teach kids",
      "Address" => "5800 Marmion Way, Los Angeles, CA, 90042",
      "Detailed Hours Of Operation" => "Monday- Friday 8:30 - 18:00",
      "Causes" => cause.name
    }.merge(overrides)
  end

  def import(row, time_zone:)
    allow(Geocoder).to receive(:search).and_return([
      Struct.new(:latitude, :longitude).new(34.111008, -118.192332)
    ])
    allow_any_instance_of(SpreadsheetImport::TimezoneDetection).to receive(:call).and_return(time_zone)
    allow_any_instance_of(SpreadsheetImport::LogoDownloader).to receive(:call).and_return(nil)

    file = spreadsheet_for(row)
    described_class.new(spreadsheet: file.path, creator: admin).call
  ensure
    file&.close!
  end

  # Regression: office hours used to be converted to UTC while the models were
  # built, so OfficeHoursValidator compared UTC values. West of Central time an
  # evening closing time crosses midnight in UTC, and because a `time` column
  # drops the day rollover it read as "Closing time must be after opening time".
  describe "office hours west of Central time" do
    it "imports an 8:30-18:00 Pacific schedule and stores it in UTC" do
      import(org_row, time_zone: "Pacific Time (US & Canada)")

      organization = Organization.find_by(name: "Asteme Learning Center Inc")
      expect(organization).to be_present

      monday = organization.locations.first.office_hours.find_by(day: 1)
      expect(monday.open_time.strftime("%H:%M")).to eq("15:30")
      expect(monday.close_time.strftime("%H:%M")).to eq("01:00")
      expect(monday.formatted_open_time.strftime("%H:%M")).to eq("08:30")
      expect(monday.formatted_close_time.strftime("%H:%M")).to eq("18:00")
    end

    it "still records a genuinely inverted schedule as an error" do
      import_log = ImportLog.create!(
        admin_user: admin, file_name: "orgs.xlsx",
        total_rows: 0, success_count: 0, error_count: 0, skipped_count: 0,
        status: "in_progress"
      )

      allow(Geocoder).to receive(:search).and_return([
        Struct.new(:latitude, :longitude).new(34.111008, -118.192332)
      ])
      allow_any_instance_of(SpreadsheetImport::TimezoneDetection).to receive(:call)
        .and_return("Pacific Time (US & Canada)")
      allow_any_instance_of(SpreadsheetImport::LogoDownloader).to receive(:call).and_return(nil)

      file = spreadsheet_for(org_row("Detailed Hours Of Operation" => "Monday 18:00 - 8:30"))
      described_class.new(spreadsheet: file.path, creator: admin, import_log: import_log).call
      file.close!

      expect(Organization.find_by(name: "Asteme Learning Center Inc")).to be_nil
      expect(import_log.reload.error_messages).to include("Closing time must be after opening time")
    end
  end

  it "keeps hours in local time for an Eastern location" do
    import(org_row, time_zone: "Eastern Time (US & Canada)")

    monday = Organization.find_by(name: "Asteme Learning Center Inc")
      .locations.first.office_hours.find_by(day: 1)

    expect(monday.open_time.strftime("%H:%M")).to eq("12:30")
    expect(monday.formatted_open_time.strftime("%H:%M")).to eq("08:30")
    expect(monday.formatted_close_time.strftime("%H:%M")).to eq("18:00")
  end
end
