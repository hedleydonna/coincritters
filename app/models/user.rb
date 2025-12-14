class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :incomes, dependent: :destroy
  has_many :income_events, dependent: :destroy
  has_many :monthly_budgets, dependent: :destroy
  has_many :expenses, through: :monthly_budgets
  has_many :expense_templates, dependent: :destroy

  # ------------------------------------------------------------------
  # Admin helper
  # ------------------------------------------------------------------
  def admin?
    admin == true
  end

  # ------------------------------------------------------------------
  # Budget access — read-only current
  # ------------------------------------------------------------------
  def current_budget
    monthly_budgets.find_by(month_year: Time.current.strftime("%Y-%m"))
  end

  # ------------------------------------------------------------------
  # Ensure current month budget exists (creates if missing)
  # ------------------------------------------------------------------
  def current_budget!
    budget = current_budget
    return budget if budget

    budget = monthly_budgets.create!(month_year: Time.current.strftime("%Y-%m"))
    budget.auto_create_expenses
    budget
  end

  # ------------------------------------------------------------------
  # Explicit next-month creation (user-triggered)
  # ------------------------------------------------------------------
  def create_next_month_budget!
    next_month = (Date.today + 1.month).strftime("%Y-%m")
    return if monthly_budgets.exists?(month_year: next_month)

    budget = monthly_budgets.create!(month_year: next_month)
    budget.auto_create_expenses
    budget
  end

  # ------------------------------------------------------------------
  # Savings — actual saved (this month and all time)
  # Note: Since is_savings field was removed, these methods return 0
  # TODO: Re-implement if savings tracking is needed with a different approach
  # ------------------------------------------------------------------
  def total_actual_savings_this_month
    return 0 unless current_budget
    # Savings scope no longer exists - return 0 for now
    0
  end

  def total_actual_savings_all_time
    # Savings scope no longer exists - return 0 for now
    0
  end

  # Optional: shortcut for dashboard
  def total_savings
    total_actual_savings_all_time
  end
end
