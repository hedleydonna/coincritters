# app/controllers/expenses_controller.rb
class ExpensesController < ApplicationController
  before_action :authenticate_user!

  def index
    @budget = current_user.current_budget!
    @expenses = @budget.expenses.order(:name)

    # For the top summary
    @total_income = @budget.total_actual_income
    @total_spent = @budget.total_spent
    @remaining = @budget.remaining_to_assign
    @bank_match = @budget.bank_match?
    @bank_difference = @budget.bank_difference
  end

  def new
    @budget = current_user.current_budget!
    @expense = @budget.expenses.new
    @expense_templates = current_user.expense_templates.active.order(:name)
  end

  def create
    @budget = current_user.current_budget!
    @expense = @budget.expenses.new(expense_params)
    
    if @expense.save
      redirect_to expenses_path, notice: "Expense added!"
    else
      @expense_templates = current_user.expense_templates.active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def expense_params
    params.require(:expense).permit(:expense_template_id, :allotted_amount, :name)
  end
end

