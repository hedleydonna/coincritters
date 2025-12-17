# app/controllers/expenses_controller.rb
class ExpensesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_expense, only: [:mark_paid, :edit, :update]

  def index
    # Auto-create current and next month if they don't exist
    current_month_str = Time.current.strftime("%Y-%m")
    next_month_str = (Date.today + 1.month).strftime("%Y-%m")
    
    # Ensure current month exists
    current_budget = current_user.current_budget!
    # Always regenerate income events for current month when visiting Money Map
    current_budget.auto_create_income_events
    # Always regenerate expenses from templates for current month
    current_budget.auto_create_expenses
    
    # Ensure next month exists
    unless current_user.monthly_budgets.exists?(month_year: next_month_str)
      current_user.create_next_month_budget!
    end
    
    # Allow viewing a specific month via params, otherwise show current month
    month_year = params[:month] || current_month_str
    
    @budget = current_user.monthly_budgets.find_by(month_year: month_year)
    
    # Also auto-create expenses for the month being viewed (if it's current or next month)
    if @budget && (month_year == current_month_str || month_year == next_month_str)
      @budget.auto_create_expenses
    end
    
    unless @budget
      # If trying to view a past month that doesn't exist, redirect to current
      if month_year < current_month_str
        redirect_to expenses_path, alert: "That month's budget doesn't exist."
        return
      else
        # For future months, just redirect to current
        redirect_to expenses_path
        return
      end
    end
    
    @expenses = @budget.expenses.order(:name)

    # For the expenses summary (expenses-focused, no income)
    @total_spent = @budget.total_spent
    @remaining = @budget.total_actual_income.to_f - @budget.total_spent.to_f
    @bank_match = @budget.bank_match?
    @bank_difference = @budget.bank_difference

    # Month navigation helpers
    @current_month = current_month_str
    @next_month_str = next_month_str
    @viewing_month = @budget.month_year
    
    # Determine if viewing current, next, or past month
    @is_current_month = @viewing_month == @current_month
    @is_next_month = @viewing_month == @next_month_str
    @is_past_month = @viewing_month < @current_month
    
    # Get current and next month budgets for tab navigation
    @current_budget = current_user.monthly_budgets.find_by(month_year: @current_month)
    @next_budget = current_user.monthly_budgets.find_by(month_year: @next_month_str)
    
    # Get all past months for dropdown
    @past_months = current_user.monthly_budgets.where("month_year < ?", @current_month).order(month_year: :desc).pluck(:month_year)
  end

  def new
    # Allow creating expense for a specific month, otherwise current month
    month_year = params[:month] || Time.current.strftime("%Y-%m")
    @budget = current_user.monthly_budgets.find_by(month_year: month_year) || current_user.current_budget!
    @expense = @budget.expenses.new
    @viewing_month = @budget.month_year
  end

  def create
    # Get month from params - check both expense hash and top-level month param
    month_year = params.dig(:expense, :month_year) || params[:month] || Time.current.strftime("%Y-%m")
    @budget = current_user.monthly_budgets.find_by(month_year: month_year) || current_user.current_budget!
    @expense = @budget.expenses.new(expense_params)
    
    if @expense.save
      # Force a full page reload to ensure the new expense appears
      redirect_to expenses_path(month: @budget.month_year), notice: "Expense added!", data: { turbo: false }
    else
      @viewing_month = @budget.month_year
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @budget = @expense.monthly_budget
    @expense_templates = current_user.expense_templates.active.order(:name)
    @viewing_month = @budget.month_year
  end

  def update
    @budget = @expense.monthly_budget
    
    if @expense.update(expense_params)
      redirect_to expenses_path(month: @budget.month_year), notice: "Expense updated!"
    else
      @expense_templates = current_user.expense_templates.active.order(:name)
      @viewing_month = @budget.month_year
      render :edit, status: :unprocessable_entity
    end
  end

  def start_next_month
    begin
      budget = current_user.create_next_month_budget!
      
      if budget
        next_month_name = Date.parse("#{budget.month_year}-01").strftime("%B %Y")
        expense_count = budget.expenses.count
        message = if expense_count > 0
          "#{next_month_name} ready! All your usual expenses (#{expense_count}) are here."
        else
          "#{next_month_name} ready! Create some expense templates to auto-add expenses next time."
        end
        redirect_to expenses_path(month: budget.month_year), notice: message
      else
        # Budget already exists - redirect to that month
        next_month = (Date.today + 1.month).strftime("%Y-%m")
        next_month_name = Date.parse("#{next_month}-01").strftime("%B %Y")
        redirect_to expenses_path(month: next_month), alert: "#{next_month_name}'s budget already exists!"
      end
    rescue => e
      Rails.logger.error "Error creating next month budget: #{e.message}"
      redirect_to expenses_path, alert: "Something went wrong. Please try again."
    end
  end

  def sweep_to_savings
    current_month = Time.current.strftime("%Y-%m")
    month_year = params[:month] || current_month
    
    # Only allow sweeping in current month
    if month_year != current_month
      redirect_to expenses_path(month: month_year), alert: "You can only sweep to savings in the current month."
      return
    end
    
    @budget = current_user.monthly_budgets.find_by(month_year: month_year)
    unless @budget
      redirect_to expenses_path, alert: "Budget not found."
      return
    end
    
    @expense = @budget.expenses.find_by(id: params[:expense_id])
    unless @expense
      redirect_to expenses_path(month: month_year), alert: "Expense not found."
      return
    end
    
    # Check if this is a savings expense
    unless @expense.name.downcase.include?("savings") || @expense.name.downcase.include?("emergency")
      redirect_to expenses_path(month: month_year), alert: "This expense is not a savings expense."
      return
    end
    
    flex_fund = @budget.unassigned
    if flex_fund <= 0
      redirect_to expenses_path(month: month_year), alert: "No flex fund available to sweep."
      return
    end
    
    amount = params[:amount].to_f
    if amount <= 0 || amount > flex_fund
      redirect_to expenses_path(month: month_year), alert: "Invalid amount. You can sweep up to #{helpers.number_to_currency(flex_fund)}."
      return
    end
    
    # Increase the expense's allotted_amount by the swept amount
    @expense.update(allotted_amount: @expense.allotted_amount + amount)
    
      redirect_to expenses_path(month: month_year), notice: "Great! You saved an extra #{helpers.number_to_currency(amount)} this month ✓"
  end

  def mark_paid
    current_month = Time.current.strftime("%Y-%m")
    
    # Only allow marking as paid in current month
    if @expense.monthly_budget.month_year != current_month
      redirect_to expenses_path(month: @expense.monthly_budget.month_year), alert: "You can only mark expenses as paid in the current month."
      return
    end
    
    # Check if already paid
    if @expense.paid?
      redirect_to expenses_path(month: current_month), notice: "This expense is already paid."
      return
    end
    
    # Calculate amount needed to mark as paid
    amount_needed = @expense.allotted_amount - @expense.spent_amount
    
    if amount_needed <= 0
      redirect_to expenses_path(month: current_month), alert: "This expense is already fully paid."
      return
    end
    
    # Create payment for the remaining amount
    payment = @expense.payments.create!(
      amount: amount_needed,
      spent_on: Date.today,
      notes: "Marked as paid"
    )
    
    redirect_to expenses_path(month: current_month), notice: "Payment added! #{helpers.number_to_currency(amount_needed)} paid to #{@expense.display_name}."
  end

  private

  def set_expense
    @expense = current_user.monthly_budgets.joins(:expenses).where(expenses: { id: params[:id] }).first&.expenses&.find_by(id: params[:id])
    unless @expense
      redirect_to expenses_path, alert: "Expense not found."
    end
  end

  def expense_params
    params.require(:expense).permit(:expense_template_id, :allotted_amount, :name)
  end
end

