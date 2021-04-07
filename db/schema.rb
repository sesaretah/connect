# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_02_15_143554) do

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
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "devices", force: :cascade do |t|
    t.integer "user_id"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_devices_on_user_id"
  end

  create_table "notification_settings", force: :cascade do |t|
    t.integer "user_id"
    t.json "notification_setting"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notification_settings_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "notifiable_id"
    t.string "notifiable_type"
    t.integer "source_user_id"
    t.json "target_user_ids"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "notification_type"
    t.boolean "seen"
    t.integer "status"
    t.string "custom_text"
    t.json "target_user_hash"
    t.index ["notifiable_id"], name: "index_notifications_on_notifiable_id"
    t.index ["notifiable_type"], name: "index_notifications_on_notifiable_type"
  end

  create_table "participations", force: :cascade do |t|
    t.integer "room_id"
    t.integer "user_id"
    t.string "device_id"
    t.string "current_role"
    t.string "uuid"
    t.json "activity_logs"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["current_role"], name: "index_participations_on_current_role"
    t.index ["uuid"], name: "index_participations_on_uuid"
  end

  create_table "profiles", force: :cascade do |t|
    t.string "name"
    t.string "surename"
    t.string "mobile"
    t.text "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "faculty"
    t.json "privacy"
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "title"
    t.json "ability"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.boolean "default_role"
    t.index ["user_id"], name: "index_roles_on_user_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "user_id"
    t.boolean "private"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid"
    t.string "secret"
    t.string "pin"
    t.boolean "activated"
    t.index ["user_id"], name: "index_rooms_on_user_id"
    t.index ["uuid"], name: "index_rooms_on_uuid"
  end

  create_table "subscribers", force: :cascade do |t|
    t.integer "user_id"
    t.integer "room_id"
    t.string "rfid"
    t.string "current_mode"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["current_mode"], name: "index_subscribers_on_current_mode"
    t.index ["rfid"], name: "index_subscribers_on_rfid"
    t.index ["room_id"], name: "index_subscribers_on_room_id"
    t.index ["user_id"], name: "index_subscribers_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "user_id"
    t.integer "room_id"
    t.string "subscription_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "uploads", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid"
    t.boolean "converted"
    t.integer "room_id"
    t.integer "user_id"
    t.integer "pages"
    t.json "dimensions"
    t.index ["room_id"], name: "index_uploads_on_room_id"
    t.index ["uuid"], name: "index_uploads_on_uuid"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "assignments"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "last_code"
    t.datetime "last_code_datetime"
    t.datetime "last_login"
    t.string "uuid"
    t.integer "current_role_id"
    t.string "username"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
end
