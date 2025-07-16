module SpreadsheetImport
  class Importer
    def initialize(spreadsheet, creator)
      @spreadsheet = spreadsheet
      @creator = creator
      @file_path = File.open(Rails.root.join("db/uploads").to_s)
      @csv_file_paths = csv_file_paths
    end
  end
end
