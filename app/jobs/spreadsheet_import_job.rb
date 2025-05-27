class SpreadsheetImportJob < ApplicationJob
  queue_as :default

  def perform(file_path, admin_user_id)
    admin = AdminUser.find(admin_user_id)
    file_name = File.basename(file_path)

    import_log = ImportLog.create!(
      admin_user: admin,
      file_name: file_name,
      total_rows: 0,
      success_count: 0,
      error_count: 0,
      skipped_count: 0,
      status: "in_progress"
    )

    file = File.open(file_path)
    parser = SpreadsheetImport::SpreadsheetParser.new(spreadsheet: file, creator: admin, import_log: import_log)
    results = parser.call

    if results[:failed_instances].any?
      error_messages = results[:failed_instances].map do |row, org|
         if org.nil?
          "Row #{row}: unknown error (org is nil)"
        else
          "Row #{row}: #{org.errors.full_messages.join(', ')}"
        end
      end.join("\n")

      import_log.update!(status: "completed", error_messages: error_messages)
    else
      import_log.update!(status: "completed", error_messages: nil)
    end


    Rails.logger.info "✅ Import completed: #{results[:ids].size} created, #{results[:failed_instances].size} failed."

  rescue => e
    import_log.update!(status: "failed", error_messages: e.message) if import_log
    Rails.logger.error "❌ Spreadsheet import failed: #{e.message}"
    raise
  ensure
    file&.close
  end
end
