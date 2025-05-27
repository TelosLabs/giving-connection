class ImportLog < ApplicationRecord
  belongs_to :admin_user

  broadcasts_to ->(log) { "import_logs" }, inserts_by: :prepend
end
