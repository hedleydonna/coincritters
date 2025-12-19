class MoneyMapController < ApplicationController
  before_action :authenticate_user!

  def index
    # Ensure current month budget exists (creates if missing)
    @budget = current_user.current_budget!
    
    # Auto-create income events and expenses for current month
    @budget.auto_create_income_events
    @budget.auto_create_expenses
    
    # Auto-fill actual_amount for events where due date has passed
    auto_fill_due_income_events
    
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
    
    # Get expenses for current month, include template for due_date
    @expenses = @budget.expenses
      .left_joins(:expense_template)
      .where("expense_templates.deleted_at IS NULL OR expense_templates.id IS NULL")
      .includes(:expense_template)
      .order("expenses.expected_on NULLS LAST, expense_templates.due_date NULLS LAST, expenses.name")
    
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

  private

  def auto_fill_due_income_events
    # Find events where received_on <= today, actual_amount is 0, and there's an estimated_amount
    current_month_str = Time.current.strftime("%Y-%m")
    due_events = current_user.income_events
      .joins("LEFT JOIN income_templates ON income_events.income_template_id = income_templates.id")
      .where(
        "month_year = ? AND received_on <= ? AND actual_amount = 0 AND income_templates.estimated_amount > 0 AND (income_templates.deleted_at IS NULL OR income_templates.id IS NULL)",
        current_month_str,
        Date.today
      )
    
    due_events.find_each do |event|
      if event.income_template && event.income_template.estimated_amount > 0
        event.update_column(:actual_amount, event.income_template.estimated_amount)
      end
    end
  end
end

