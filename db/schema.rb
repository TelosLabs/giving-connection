# frozen_string_literal: true

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

ActiveRecord::Schema.define(version: 20_211_005_184_719) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'plpgsql'

  create_table 'admin_users', force: :cascade do |t|
    t.string 'email', default: '', null: false
    t.string 'encrypted_password', default: '', null: false
    t.string 'reset_password_token'
    t.datetime 'reset_password_sent_at'
    t.datetime 'remember_created_at'
    t.integer 'sign_in_count', default: 0, null: false
    t.datetime 'current_sign_in_at'
    t.datetime 'last_sign_in_at'
    t.string 'current_sign_in_ip'
    t.string 'last_sign_in_ip'
    t.integer 'failed_attempts', default: 0, null: false
    t.string 'unlock_token'
    t.datetime 'locked_at'
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.index ['email'], name: 'index_admin_users_on_email', unique: true
    t.index ['reset_password_token'], name: 'index_admin_users_on_reset_password_token', unique: true
  end

  create_table 'contact_informations', force: :cascade do |t|
    t.string 'first_name'
    t.string 'last_name'
    t.string 'title'
    t.string 'email'
    t.bigint 'organization_id', null: false
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.index ['organization_id'], name: 'index_contact_informations_on_organization_id'
  end

  create_table 'organizations', force: :cascade do |t|
    t.string 'name', null: false
    t.string 'ein_number', null: false
    t.string 'irs_ntee_code', null: false
    t.string 'website'
    t.string 'scope_of_work', null: false
    t.string 'creator_type'
    t.bigint 'creator_id'
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.text 'mission_statement_en', null: false
    t.text 'mission_statement_es'
    t.text 'vision_statement_en', null: false
    t.text 'vision_statement_es'
    t.text 'tagline_en', null: false
    t.text 'tagline_es'
    t.text 'description_en', null: false
    t.text 'description_es'
    t.index %w[creator_type creator_id], name: 'index_organizations_on_creator'
    t.index ['description_en'], name: 'index_organizations_on_description_en'
    t.index ['ein_number'], name: 'index_organizations_on_ein_number', unique: true
    t.index ['mission_statement_en'], name: 'index_organizations_on_mission_statement_en'
    t.index ['name'], name: 'index_organizations_on_name', unique: true
    t.index ['scope_of_work'], name: 'index_organizations_on_scope_of_work'
    t.index ['tagline_en'], name: 'index_organizations_on_tagline_en'
    t.index ['vision_statement_en'], name: 'index_organizations_on_vision_statement_en'
  end

  create_table 'phone_numbers', force: :cascade do |t|
    t.string 'number'
    t.boolean 'main', default: true
    t.bigint 'contact_information_id', null: false
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.index ['contact_information_id'], name: 'index_phone_numbers_on_contact_information_id'
  end

  create_table 'social_medias', force: :cascade do |t|
    t.string 'facebook'
    t.string 'instagram'
    t.string 'twitter'
    t.string 'linkedin'
    t.string 'youtube'
    t.string 'blog'
    t.bigint 'organization_id', null: false
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.index ['organization_id'], name: 'index_social_medias_on_organization_id'
  end

  create_table 'users', force: :cascade do |t|
    t.string 'email', default: '', null: false
    t.string 'encrypted_password', default: '', null: false
    t.string 'reset_password_token'
    t.datetime 'reset_password_sent_at'
    t.datetime 'remember_created_at'
    t.integer 'sign_in_count', default: 0, null: false
    t.datetime 'current_sign_in_at'
    t.datetime 'last_sign_in_at'
    t.string 'current_sign_in_ip'
    t.string 'last_sign_in_ip'
    t.string 'confirmation_token'
    t.datetime 'confirmed_at'
    t.datetime 'confirmation_sent_at'
    t.string 'unconfirmed_email'
    t.integer 'failed_attempts', default: 0, null: false
    t.string 'unlock_token'
    t.datetime 'locked_at'
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.index ['confirmation_token'], name: 'index_users_on_confirmation_token', unique: true
    t.index ['email'], name: 'index_users_on_email', unique: true
    t.index ['reset_password_token'], name: 'index_users_on_reset_password_token', unique: true
    t.index ['unlock_token'], name: 'index_users_on_unlock_token', unique: true
  end

  add_foreign_key 'contact_informations', 'organizations'
  add_foreign_key 'phone_numbers', 'contact_informations'
  add_foreign_key 'social_medias', 'organizations'
end
