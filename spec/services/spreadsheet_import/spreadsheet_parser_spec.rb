require "rails_helper"

# A Monday, so the weekday office hours the fixtures build are the ones
# Location#open_now? looks at, and inside PDT so the UTC close crosses midnight
# — the shape that used to make "Open Now" miss the location.
MONDAY_MIDDAY_PACIFIC = Time.find_zone!("Pacific Time (US & Canada)").local(2026, 6, 1, 13, 0, 0)

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

  def import(row, time_zone:, import_log: nil)
    allow(Geocoder).to receive(:search).and_return([
      Struct.new(:latitude, :longitude).new(34.111008, -118.192332)
    ])
    allow_any_instance_of(SpreadsheetImport::TimezoneDetection).to receive(:call).and_return(time_zone)
    allow_any_instance_of(SpreadsheetImport::LogoDownloader).to receive(:call).and_return(nil)

    file = spreadsheet_for(row)
    described_class.new(spreadsheet: file.path, creator: admin, import_log: import_log).call
  ensure
    file&.close!
  end

  def new_import_log
    ImportLog.create!(
      admin_user: admin, file_name: "orgs.xlsx",
      total_rows: 0, success_count: 0, error_count: 0, skipped_count: 0,
      status: "in_progress"
    )
  end

  def imported_location
    Organization.find_by(name: "Asteme Learning Center Inc")&.locations&.first
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

    # A cell that runs backwards is no longer worth an entire organization: it
    # imports without weekly hours, and the cell we could not read is named in
    # the log so an operator can go and fix it.
    it "imports the organization and reports a schedule that runs backwards" do
      import_log = new_import_log
      import(org_row("Detailed Hours Of Operation" => "Monday 18:00 - 8:30"),
        time_zone: "Pacific Time (US & Canada)", import_log: import_log)

      expect(imported_location.office_hours).to be_empty
      expect(imported_location.non_standard_office_hours).to eq("no_set_business_hours")
      expect(import_log.reload.error_messages).to include("Hours not understood")
    end

    it "reports a cell it cannot read instead of publishing the location as closed" do
      import_log = new_import_log
      import(org_row("Detailed Hours Of Operation" => "Funday 9:00-17:00"),
        time_zone: "Pacific Time (US & Canada)", import_log: import_log)

      expect(imported_location.office_hours).to be_empty
      expect(imported_location.non_standard_office_hours).to eq("no_set_business_hours")
      expect(import_log.reload.error_messages).to include("Funday 9:00-17:00")
    end

    it "records a day-less 24 hour cell as always open" do
      import(org_row("Detailed Hours Of Operation" => "Open 24 hours"),
        time_zone: "Pacific Time (US & Canada)")

      expect(imported_location.non_standard_office_hours).to eq("always_open")
    end

    # "24:00" used to cast to the next day's midnight, survive validation, and
    # then be strftime'd back to 00:00 — persisting a zero-length window that
    # rendered as "12:00 AM - 12:00 AM / Closed".
    it "persists an all-day cell as a window that is actually open" do
      import(org_row("Detailed Hours Of Operation" => "Monday: 24 hours"),
        time_zone: "Pacific Time (US & Canada)")

      monday = imported_location.office_hours.find_by(day: 1)
      expect(monday.open_time).not_to eq(monday.close_time)
      expect(monday.formatted_open_time.strftime("%H:%M")).to eq("00:00")
      expect(monday.formatted_close_time.strftime("%H:%M")).to eq("23:59")

      Timecop.freeze(MONDAY_MIDDAY_PACIFIC) { expect(monday.reload).to be_open_now }
    end

    # The rows this import writes are inverted in UTC by design; open_now? has
    # to restore the day rollover or every west-of-Central location with an
    # evening close disappears from the "Open Now" filter.
    it "reports a Pacific location as open during its own business hours" do
      import(org_row, time_zone: "Pacific Time (US & Canada)")
      location = imported_location

      Timecop.freeze(MONDAY_MIDDAY_PACIFIC) do
        expect(location.office_hours.find_by(day: 1)).to be_open_now
        expect(location).to be_open_now
      end
    end

    it "reports a Pacific location as closed outside its business hours" do
      import(org_row, time_zone: "Pacific Time (US & Canada)")
      location = imported_location

      Timecop.freeze(MONDAY_MIDDAY_PACIFIC.change(hour: 22)) do
        expect(location.office_hours.find_by(day: 1)).not_to be_open_now
      end
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
