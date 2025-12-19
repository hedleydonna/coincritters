class MoneyMapController < ApplicationController
  before_action :authenticate_user!

  def index
    # Ensure current month budget exists (creates if missing)
    @budget = current_user.current_budget!
    
    # Calculate all stats
    @total_income = @budget.total_actual_income.to_f
    @available_income = @budget.available_income.to_f
    @carryover = @budget.carryover_from_previous_month.to_f
    @expected_income = @budget.expected_income.to_f
    @total_spent = @budget.total_spent.to_f
    @total_allotted = @budget.total_allotted.to_f
    @remaining = (@budget.available_income.to_f - @budget.total_spent.to_f)
    @remaining_to_assign = @budget.remaining_to_assign.to_f
    
    # Get income events for current month
    current_month_str = Time.current.strftime("%Y-%m")
    @income_events = current_user.income_events
      .joins("LEFT JOIN income_templates ON income_events.income_template_id = income_templates.id")
      .where(
        "month_year = ? AND (income_templates.deleted_at IS NULL OR income_templates.id IS NULL)",
        current_month_str
      )
      .order(:received_on)
    
    # Get expenses for current month
    @expenses = @budget.expenses
      .left_joins(:expense_template)
      .where("expense_templates.deleted_at IS NULL OR expense_templates.id IS NULL")
      .order(:name)
    
    # Month info
    @viewing_month = current_month_str
    @month_name = Date.parse("#{@viewing_month}-01").strftime("%B %Y")
  rescue => e
    Rails.logger.error "Money Map error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    @budget = nil
    @total_income = 0
    @available_income = 0
    @carryover = 0
    @expected_income = 0
    @total_spent = 0
    @total_allotted = 0
    @remaining = 0
    @remaining_to_assign = 0
    @income_events = []
    @expenses = []
  end
end

