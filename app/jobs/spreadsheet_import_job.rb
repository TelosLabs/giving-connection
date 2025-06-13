class SpreadsheetImportJob < ApplicationJob
  queue_as :default
  discard_on StandardError

  def perform(blob_signed_id, admin_user_id, original_filename)
    admin = AdminUser.find(admin_user_id)

    import_log = ImportLog.create!(
      admin_user: admin,
      file_name: original_filename,
      total_rows: 0,
      success_count: 0,
      error_count: 0,
      skipped_count: 0,
      status: "in_progress"
    )

    blob = ActiveStorage::Blob.find_signed(blob_signed_id)

    blob.open do |file|
      parser = SpreadsheetImport::SpreadsheetParser.new(
        spreadsheet: file,
        creator: admin,
        import_log: import_log
      )
      parser.call
    end

    Rails.logger.info "✅ Import completed: #{original_filename}"
  rescue => e
    import_log&.update!(status: "failed", error_messages: e.message)
    Rails.logger.error "❌ Spreadsheet import failed: #{e.message}"
  end
end
