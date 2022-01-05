# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_01_05_124317) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "pg_trgm"
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "alerts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "distance"
    t.string "city"
    t.string "state"
    t.string "services"
    t.string "open_now"
    t.string "open_weekends"
    t.string "keyword"
    t.string "beneficiary_groups"
    t.string "frequency", default: "weekly"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_alerts_on_user_id"
  end

  create_table "beneficiary_groups", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "beneficiary_subcategories", force: :cascade do |t|
    t.string "name"
    t.bigint "beneficiary_group_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["beneficiary_group_id"], name: "index_beneficiary_subcategories_on_beneficiary_group_id"
  end

  create_table "causes", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "favorite_locations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "location_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["location_id"], name: "index_favorite_locations_on_location_id"
    t.index ["user_id"], name: "index_favorite_locations_on_user_id"
  end

  create_table "location_services", force: :cascade do |t|
    t.string "description"
    t.bigint "location_id", null: false
    t.bigint "service_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["location_id"], name: "index_location_services_on_location_id"
    t.index ["service_id"], name: "index_location_services_on_service_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "address"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.geography "lonlat", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}, null: false
    t.string "website"
    t.boolean "main", default: false, null: false
    t.boolean "physical"
    t.boolean "offer_services"
    t.bigint "organization_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "appointment_only", default: false
    t.string "name", null: false
    t.string "email"
    t.index ["lonlat"], name: "index_locations_on_lonlat", using: :gist
    t.index ["organization_id"], name: "index_locations_on_organization_id"
  end

  create_table "messages", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone"
    t.string "subject"
    t.string "organization_name", null: false
    t.string "organization_website"
    t.string "organization_ein"
    t.text "content"
  end

  create_table "office_hours", force: :cascade do |t|
    t.integer "day", null: false
    t.time "open_time"
    t.time "close_time"
    t.boolean "closed", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "location_id"
    t.index ["location_id"], name: "index_office_hours_on_location_id"
  end

  create_table "organization_admins", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "user_id", null: false
    t.string "role"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["organization_id"], name: "index_organization_admins_on_organization_id"
    t.index ["user_id"], name: "index_organization_admins_on_user_id"
  end

  create_table "organization_beneficiaries", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "beneficiary_subcategory_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["beneficiary_subcategory_id"], name: "index_organization_beneficiaries_on_beneficiary_subcategory_id"
    t.index ["organization_id"], name: "index_organization_beneficiaries_on_organization_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "ein_number", null: false
    t.string "irs_ntee_code", null: false
    t.string "website"
    t.string "scope_of_work", null: false
    t.string "creator_type"
    t.bigint "creator_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "mission_statement_en", null: false
    t.text "mission_statement_es"
    t.text "vision_statement_en"
    t.text "vision_statement_es"
    t.text "tagline_en"
    t.text "tagline_es"
    t.string "second_name"
    t.string "phone_number"
    t.string "email"
    t.boolean "active", default: true
    t.index ["creator_type", "creator_id"], name: "index_organizations_on_creator"
    t.index ["ein_number"], name: "index_organizations_on_ein_number", unique: true
    t.index ["mission_statement_en"], name: "index_organizations_on_mission_statement_en"
    t.index ["name"], name: "index_organizations_on_name", unique: true
    t.index ["scope_of_work"], name: "index_organizations_on_scope_of_work"
    t.index ["tagline_en"], name: "index_organizations_on_tagline_en"
    t.index ["vision_statement_en"], name: "index_organizations_on_vision_statement_en"
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.string "searchable_type"
    t.bigint "searchable_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable"
  end

  create_table "phone_numbers", force: :cascade do |t|
    t.string "number"
    t.boolean "main"
    t.bigint "location_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["location_id"], name: "index_phone_numbers_on_location_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "name"
    t.bigint "cause_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["cause_id"], name: "index_services_on_cause_id"
  end

  create_table "social_medias", force: :cascade do |t|
    t.string "facebook"
    t.string "instagram"
    t.string "twitter"
    t.string "linkedin"
    t.string "youtube"
    t.string "blog"
    t.bigint "organization_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["organization_id"], name: "index_social_medias_on_organization_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.bigint "organization_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_tags_on_name"
    t.index ["organization_id"], name: "index_tags_on_organization_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "name"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "alerts", "users"
  add_foreign_key "beneficiary_subcategories", "beneficiary_groups"
  add_foreign_key "favorite_locations", "locations"
  add_foreign_key "favorite_locations", "users"
  add_foreign_key "location_services", "locations"
  add_foreign_key "location_services", "services"
  add_foreign_key "locations", "organizations"
  add_foreign_key "organization_admins", "organizations"
  add_foreign_key "organization_admins", "users"
  add_foreign_key "organization_beneficiaries", "beneficiary_subcategories"
  add_foreign_key "organization_beneficiaries", "organizations"
  add_foreign_key "phone_numbers", "locations"
  add_foreign_key "services", "causes"
  add_foreign_key "social_medias", "organizations"
  add_foreign_key "tags", "organizations"
end
