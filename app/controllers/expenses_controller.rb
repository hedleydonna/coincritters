# app/controllers/expenses_controller.rb
class ExpensesController < ApplicationController
  before_action :authenticate_user!

  def index
    # Allow viewing a specific month via params, otherwise show current month
    month_year = params[:month] || Time.current.strftime("%Y-%m")
    
    @budget = current_user.monthly_budgets.find_by(month_year: month_year)
    # If viewing a specific month that doesn't exist, fall back to current month
    @budget ||= current_user.current_budget! if month_year == Time.current.strftime("%Y-%m")
    
    unless @budget
      month_name = Date.parse("#{month_year}-01").strftime("%B %Y") rescue month_year
      redirect_to expenses_path, alert: "#{month_name}'s budget doesn't exist yet."
      return
    end
    
    @expenses = @budget.expenses.order(:name)

    # For the top summary
    @total_income = @budget.total_actual_income
    @total_spent = @budget.total_spent
    @remaining = @budget.remaining_to_assign
    @bank_match = @budget.bank_match?
    @bank_difference = @budget.bank_difference

    # Month navigation helpers
    @current_month = Time.current.strftime("%Y-%m")
    @viewing_month = @budget.month_year
    @all_months = current_user.monthly_budgets.pluck(:month_year).sort
    
    # Calculate previous and next months
    current_index = @all_months.index(@viewing_month)
    @previous_month = current_index && current_index > 0 ? @all_months[current_index - 1] : nil
    @next_month = current_index && current_index < @all_months.length - 1 ? @all_months[current_index + 1] : nil
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

