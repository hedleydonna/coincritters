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

ActiveRecord::Schema[7.1].define(version: 2025_12_08_222814) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "budgets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "month"
    t.integer "year"
    t.decimal "income", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pay_frequency", default: "monthly"
    t.decimal "pay_amount", precision: 10, scale: 2
    t.index ["user_id"], name: "index_budgets_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "category_type", default: "discretionary", null: false
    t.decimal "default_amount", precision: 10, scale: 2
    t.string "color"
    t.string "icon"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_categories_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "envelopes", force: :cascade do |t|
    t.bigint "budget_id", null: false
    t.string "name"
    t.decimal "allocated_amount", precision: 10, scale: 2, default: "0.0"
    t.string "color"
    t.string "icon"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "envelope_type", default: "discretionary"
    t.boolean "carry_over", default: true
    t.bigint "category_id", null: false
    t.index ["budget_id", "category_id"], name: "index_envelopes_on_budget_id_and_category_id", unique: true
    t.index ["budget_id"], name: "index_envelopes_on_budget_id"
    t.index ["category_id"], name: "index_envelopes_on_category_id"
  end

  create_table "income_sources", force: :cascade do |t|
    t.bigint "budget_id", null: false
    t.string "name", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "schedule_type", null: false
    t.integer "day_of_month"
    t.string "frequency"
    t.date "start_date"
    t.integer "occurrence_month"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "one_time", default: false
    t.integer "expected_month"
    t.integer "expected_year"
    t.index ["budget_id"], name: "index_income_sources_on_budget_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "envelope_id"
    t.bigint "budget_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "transaction_type", null: false
    t.string "description"
    t.date "transaction_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "income_source", default: "paycheck"
    t.index ["budget_id"], name: "index_transactions_on_budget_id"
    t.index ["envelope_id"], name: "index_transactions_on_envelope_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_name"
    t.index ["display_name"], name: "index_users_on_display_name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "budgets", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "envelopes", "budgets"
  add_foreign_key "envelopes", "categories"
  add_foreign_key "income_sources", "budgets"
  add_foreign_key "transactions", "budgets"
  add_foreign_key "transactions", "envelopes"
end
