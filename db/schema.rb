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

ActiveRecord::Schema[7.1].define(version: 2025_12_10_211507) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bill_payments", force: :cascade do |t|
    t.bigint "envelope_id", null: false
    t.decimal "actual_paid_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.date "paid_on", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["envelope_id", "paid_on"], name: "index_bill_payments_on_envelope_id_and_paid_on"
    t.index ["envelope_id"], name: "index_bill_payments_on_envelope_id"
  end

  create_table "envelopes", force: :cascade do |t|
    t.bigint "monthly_budget_id", null: false
    t.string "spending_group_name", null: false
    t.decimal "allotted_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "spent_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "spending_category_id", null: false
    t.index ["monthly_budget_id", "spending_category_id"], name: "index_envelopes_on_budget_and_spending_category", unique: true
    t.index ["monthly_budget_id"], name: "index_envelopes_on_monthly_budget_id"
    t.index ["spending_category_id"], name: "index_envelopes_on_spending_category_id"
  end

  create_table "income_events", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "income_id"
    t.string "custom_label"
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
    t.boolean "auto_create", default: false, null: false
    t.integer "auto_day_of_month"
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

  create_table "spending_categories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.integer "group_type", default: 1, null: false
    t.boolean "is_savings", default: false, null: false
    t.decimal "default_amount", precision: 12, scale: 2, default: "0.0"
    t.boolean "auto_create", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "group_type"], name: "index_spending_categories_on_user_id_and_group_type"
    t.index ["user_id", "name"], name: "index_spending_categories_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_spending_categories_on_user_id"
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

  create_table "variable_spending", force: :cascade do |t|
    t.bigint "envelope_id", null: false
    t.decimal "amount", precision: 12, scale: 2, default: "0.0", null: false
    t.date "spent_on", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["envelope_id", "spent_on"], name: "index_variable_spending_on_envelope_id_and_spent_on"
    t.index ["envelope_id"], name: "index_variable_spending_on_envelope_id"
  end

  add_foreign_key "bill_payments", "envelopes", on_delete: :cascade
  add_foreign_key "envelopes", "monthly_budgets", on_delete: :cascade
  add_foreign_key "envelopes", "spending_categories", on_delete: :cascade
  add_foreign_key "income_events", "incomes", on_delete: :cascade
  add_foreign_key "income_events", "users", on_delete: :cascade
  add_foreign_key "incomes", "users", on_delete: :cascade
  add_foreign_key "monthly_budgets", "users", on_delete: :cascade
  add_foreign_key "spending_categories", "users", on_delete: :cascade
  add_foreign_key "variable_spending", "envelopes", on_delete: :cascade
end
