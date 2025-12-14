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

ActiveRecord::Schema[7.1].define(version: 2025_12_15_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "expense_templates", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.decimal "default_amount", precision: 12, scale: 2, default: "0.0"
    t.boolean "auto_create", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_active", default: true, null: false
    t.string "frequency", default: "monthly"
    t.date "due_date"
    t.index ["is_active"], name: "index_expense_templates_on_is_active"
    t.index ["user_id", "name"], name: "index_expense_templates_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_expense_templates_on_user_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.bigint "monthly_budget_id", null: false
    t.decimal "allotted_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "expense_template_id"
    t.string "name"
    t.index ["expense_template_id"], name: "index_expenses_on_expense_template_id"
    t.index ["monthly_budget_id", "expense_template_id"], name: "index_expenses_on_budget_and_template_when_template_present", unique: true, where: "(expense_template_id IS NOT NULL)"
    t.index ["monthly_budget_id", "name"], name: "index_envelopes_on_budget_and_name_override"
    t.index ["monthly_budget_id"], name: "index_expenses_on_monthly_budget_id"
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

  create_table "payments", force: :cascade do |t|
    t.bigint "expense_id", null: false
    t.decimal "amount", precision: 12, scale: 2, default: "0.0", null: false
    t.date "spent_on", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expense_id", "spent_on"], name: "index_payments_on_expense_id_and_spent_on"
    t.index ["expense_id"], name: "index_payments_on_expense_id"
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

  add_foreign_key "expense_templates", "users", on_delete: :cascade
  add_foreign_key "expenses", "expense_templates", on_delete: :cascade
  add_foreign_key "expenses", "monthly_budgets", on_delete: :cascade
  add_foreign_key "income_events", "incomes", on_delete: :cascade
  add_foreign_key "income_events", "users", on_delete: :cascade
  add_foreign_key "incomes", "users", on_delete: :cascade
  add_foreign_key "monthly_budgets", "users", on_delete: :cascade
  add_foreign_key "payments", "expenses", on_delete: :cascade
end
