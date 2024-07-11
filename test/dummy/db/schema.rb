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

ActiveRecord::Schema[7.1].define(version: 2024_05_08_190642) do
  create_table "close_encounters_participant_events", force: :cascade do |t|
    t.text "response"
    t.integer "close_encounters_participant_service_id", null: false
    t.integer "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["close_encounters_participant_service_id"], name: "idx_on_close_encounters_participant_service_id_4e69f5fd33"
  end

  create_table "close_encounters_participant_services", force: :cascade do |t|
    t.string "name", null: false
    t.text "connection_info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_close_encounters_participant_services_on_name", unique: true
  end

  add_foreign_key "close_encounters_participant_events", "close_encounters_participant_services"
end
