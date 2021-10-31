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

ActiveRecord::Schema.define(version: 2021_10_28_214229) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "organization_beneficiaries", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "beneficiary_subcategory_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["beneficiary_subcategory_id"], name: "index_organization_beneficiaries_on_beneficiary_subcategory_id"
    t.index ["organization_id"], name: "index_organization_beneficiaries_on_organization_id"
  end

  create_table "organization_categories", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["category_id"], name: "index_organization_categories_on_category_id"
    t.index ["organization_id"], name: "index_organization_categories_on_organization_id"
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
    t.text "vision_statement_en", null: false
    t.text "vision_statement_es"
    t.text "tagline_en", null: false
    t.text "tagline_es"
    t.text "description_en", null: false
    t.text "description_es"
    t.index ["creator_type", "creator_id"], name: "index_organizations_on_creator"
    t.index ["description_en"], name: "index_organizations_on_description_en"
    t.index ["ein_number"], name: "index_organizations_on_ein_number", unique: true
    t.index ["mission_statement_en"], name: "index_organizations_on_mission_statement_en"
    t.index ["name"], name: "index_organizations_on_name", unique: true
    t.index ["scope_of_work"], name: "index_organizations_on_scope_of_work"
    t.index ["tagline_en"], name: "index_organizations_on_tagline_en"
    t.index ["vision_statement_en"], name: "index_organizations_on_vision_statement_en"
  end

  create_table "services", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "organization_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["organization_id"], name: "index_services_on_organization_id"
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
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "beneficiary_subcategories", "beneficiary_groups"
  add_foreign_key "organization_beneficiaries", "beneficiary_subcategories"
  add_foreign_key "organization_beneficiaries", "organizations"
  add_foreign_key "organization_categories", "categories"
  add_foreign_key "organization_categories", "organizations"
  add_foreign_key "services", "organizations"
  add_foreign_key "social_medias", "organizations"
  add_foreign_key "tags", "organizations"
end
