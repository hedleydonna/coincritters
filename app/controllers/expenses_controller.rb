# app/controllers/expenses_controller.rb
class ExpensesController < ApplicationController
  before_action :authenticate_user!

  def index
    # Auto-create current and next month if they don't exist
    current_month_str = Time.current.strftime("%Y-%m")
    next_month_str = (Date.today + 1.month).strftime("%Y-%m")
    
    # Ensure current month exists
    current_user.current_budget!
    
    # Ensure next month exists
    unless current_user.monthly_budgets.exists?(month_year: next_month_str)
      current_user.create_next_month_budget!
    end
    
    # Allow viewing a specific month via params, otherwise show current month
    month_year = params[:month] || current_month_str
    
    @budget = current_user.monthly_budgets.find_by(month_year: month_year)
    
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

    # For the top summary
    @total_income = @budget.total_actual_income
    @total_spent = @budget.total_spent
    @remaining = @budget.remaining_to_assign
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
    @expense_templates = current_user.expense_templates.active.order(:name)
    @viewing_month = @budget.month_year
  end

  def create
    month_year = params[:expense][:month_year] || params[:month] || Time.current.strftime("%Y-%m")
    @budget = current_user.monthly_budgets.find_by(month_year: month_year) || current_user.current_budget!
    @expense = @budget.expenses.new(expense_params)
    
    if @expense.save
      redirect_to expenses_path(month: @budget.month_year), notice: "Expense added!"
    else
      @expense_templates = current_user.expense_templates.active.order(:name)
      @viewing_month = @budget.month_year
      render :new, status: :unprocessable_entity
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

  private

  def expense_params
    params.require(:expense).permit(:expense_template_id, :allotted_amount, :name)
  end
end

