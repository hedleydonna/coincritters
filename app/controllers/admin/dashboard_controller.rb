# frozen_string_literal: true

class Admin::DashboardController < Admin::BaseController
  def index
    @user_count = User.count
    @recent_users = User.order(created_at: :desc).limit(5)
    @income_count = Income.count
    @active_income_count = Income.active.count
    @recent_incomes = Income.includes(:user).order(created_at: :desc).limit(5)
    @income_event_count = IncomeEvent.count
    @recent_income_events = IncomeEvent.includes(:user, :income).order(created_at: :desc).limit(5)
    @monthly_budget_count = MonthlyBudget.count
    @recent_monthly_budgets = MonthlyBudget.includes(:user).order(created_at: :desc).limit(5)
    @expense_count = Expense.count
    @recent_expenses = Expense.includes(monthly_budget: :user).order(created_at: :desc).limit(5)
    @payment_count = Payment.count
    @recent_payments = Payment.includes(expense: { monthly_budget: :user }).recent.limit(5)
    @expense_template_count = ExpenseTemplate.active.count
    @recent_expense_templates = ExpenseTemplate.active.includes(:user).reorder(created_at: :desc).limit(5)
  end
end

