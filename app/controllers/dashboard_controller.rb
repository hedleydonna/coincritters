class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin, only: [:reset_data, :reset_all_data, :clear_income_events, :clear_expenses]

  def index
    # Ensure current month budget exists (creates if missing)
    @budget = current_user.current_budget!
    
    # Calculate quick stats with safe nil handling
    @total_income = @budget.total_actual_income.to_f
    @available_income = @budget.available_income.to_f
    @carryover = @budget.carryover_from_previous_month.to_f
    @expected_income = @budget.expected_income.to_f
    @total_spent = @budget.total_spent.to_f
    @remaining = (@budget.available_income.to_f - @budget.total_spent.to_f)
    @remaining_to_assign = @budget.remaining_to_assign.to_f
  rescue => e
    # Log error and set safe defaults
    Rails.logger.error "Dashboard error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    @budget = nil
    @total_income = 0
    @available_income = 0
    @carryover = 0
    @expected_income = 0
    @total_spent = 0
    @remaining = 0
    @remaining_to_assign = 0
  end

  def reset_data
    # Delete monthly budgets (cascades to expenses, which cascade to payments)
    current_user.monthly_budgets.destroy_all
    
    # Delete all income events
    current_user.income_events.destroy_all
    
    redirect_to money_map_path, notice: "All expenses, payments, monthly budgets, and income events have been deleted.", status: :see_other
  end

  def reset_all_data
    # Delete monthly budgets (cascades to expenses, which cascade to payments)
    current_user.monthly_budgets.destroy_all
    
    # Delete all income events
    current_user.income_events.destroy_all
    
    # Delete all templates (including soft-deleted ones)
    current_user.income_templates.unscoped.where(user_id: current_user.id).destroy_all
    current_user.expense_templates.unscoped.where(user_id: current_user.id).destroy_all
    
    redirect_to money_map_path, notice: "All data has been deleted, including templates.", status: :see_other
  end

  def clear_income_events
    count = current_user.income_events.count
    # Use delete_all to bypass callbacks, then manually update budgets
    current_user.income_events.delete_all
    
    # Manually update all monthly budgets' total_actual_income to 0
    current_user.monthly_budgets.update_all(total_actual_income: 0.0)
    
    redirect_to money_map_path, notice: "Cleared #{count} income event#{'s' if count != 1}.", status: :see_other
  end

  def clear_expenses
    count = current_user.expenses.count
    # Can't use destroy_all on has_many :through, so find expenses directly
    Expense.where(id: current_user.expenses.pluck(:id)).destroy_all
    
    redirect_to money_map_path, notice: "Cleared #{count} expense#{'s' if count != 1}.", status: :see_other
  end

  private

  def require_admin
    unless current_user.admin?
      redirect_to dashboard_path, alert: "Access denied. Admin privileges required."
    end
  end
end
