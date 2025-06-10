class SpreadsheetImportJob < ApplicationJob
  queue_as :default
  discard_on StandardError

  def perform(file_path, admin_user_id, original_filename)
    admin = AdminUser.find(admin_user_id)
    File.basename(file_path)

    import_log = ImportLog.create!(
      admin_user: admin,
      file_name: original_filename,
      total_rows: 0,
      success_count: 0,
      error_count: 0,
      skipped_count: 0,
      status: "in_progress"
    )

    file = File.open(file_path)
    parser = SpreadsheetImport::SpreadsheetParser.new(spreadsheet: file, creator: admin, import_log: import_log)
    parser.call
  rescue => e
    import_log&.update!(status: "failed", error_messages: e.message)
    Rails.logger.error "❌ Spreadsheet import failed: #{e.message}"
  ensure
    file&.close
    if file_path && File.exist?(file_path)
      File.delete(file_path)
      Rails.logger.info "🧹 Temp file #{file_path} deleted."
    end
  end
end
