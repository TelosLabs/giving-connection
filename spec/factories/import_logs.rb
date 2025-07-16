FactoryBot.define do
  factory :import_log do
    admin_user { nil }
    file_name { "MyString" }
    total_rows { 1 }
    success_count { 1 }
    error_count { 1 }
    skipped_count { 1 }
    status { "MyString" }
    error_messages { "MyText" }
  end
end
