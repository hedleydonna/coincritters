class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # Ensure current month budget exists (creates if missing)
    @budget = current_user.current_budget!
    
    # Calculate quick stats with safe nil handling
    @total_income = @budget.total_actual_income.to_f
    @expected_income = @budget.expected_income.to_f
    @total_spent = @budget.total_spent.to_f
    @remaining = (@budget.total_actual_income.to_f - @budget.total_spent.to_f)
    @flex_fund = @budget.remaining_to_assign.to_f
  rescue => e
    # Log error and set safe defaults
    Rails.logger.error "Dashboard error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    @budget = nil
    @total_income = 0
    @expected_income = 0
    @total_spent = 0
    @remaining = 0
    @flex_fund = 0
  end
end
