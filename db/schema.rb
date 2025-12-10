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

ActiveRecord::Schema[7.1].define(version: 2025_12_10_003311) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "income_events", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "income_id"
    t.string "income_type", default: "Paycheck", null: false
    t.string "month_year", null: false
    t.string "assigned_month_year"
    t.date "received_on", null: false
    t.decimal "actual_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["income_id", "month_year"], name: "index_income_events_on_income_id_and_month_year"
    t.index ["income_id"], name: "index_income_events_on_income_id"
    t.index ["user_id", "assigned_month_year"], name: "index_income_events_on_assigned_month"
    t.index ["user_id", "month_year"], name: "index_income_events_on_user_id_and_month_year"
    t.index ["user_id"], name: "index_income_events_on_user_id"
  end

  create_table "incomes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "frequency", default: "monthly", null: false
    t.decimal "estimated_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "active"], name: "index_incomes_on_user_id_and_active"
    t.index ["user_id", "name"], name: "index_incomes_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_incomes_on_user_id"
  end

  create_table "monthly_budgets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "month_year", null: false
    t.decimal "total_actual_income", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "flex_fund", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "bank_balance", precision: 12, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "month_year"], name: "index_monthly_budgets_on_user_id_and_month_year", unique: true
    t.index ["user_id"], name: "index_monthly_budgets_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "display_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "income_events", "incomes", on_delete: :cascade
  add_foreign_key "income_events", "users", on_delete: :cascade
  add_foreign_key "incomes", "users", on_delete: :cascade
  add_foreign_key "monthly_budgets", "users", on_delete: :cascade
end
