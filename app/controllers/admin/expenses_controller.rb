# frozen_string_literal: true

class Admin::ExpensesController < Admin::BaseController
  before_action :set_expense, only: [:show, :edit, :update, :destroy]

  def index
    @expenses = Expense.includes(monthly_budget: :user).order(created_at: :desc)
    @total_expenses = Expense.count
  end

  def show
  end

  def new
    @expense = Expense.new
    @monthly_budgets = MonthlyBudget.includes(:user).order(created_at: :desc)
    @expense_templates = ExpenseTemplate.active.includes(:user)
  end

  def create
    @expense = Expense.new(expense_params)
    if @expense.save
      redirect_to admin_expense_path(@expense), notice: "Expense was successfully created."
    else
      @monthly_budgets = MonthlyBudget.includes(:user).order(created_at: :desc)
      @expense_templates = ExpenseTemplate.active.includes(:user)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @monthly_budgets = MonthlyBudget.includes(:user).order(created_at: :desc)
    @expense_templates = ExpenseTemplate.active.includes(:user)
  end

  def update
    if @expense.update(expense_params)
      redirect_to admin_expense_path(@expense), notice: "Expense was successfully updated."
    else
      @monthly_budgets = MonthlyBudget.includes(:user).order(created_at: :desc)
      @expense_templates = ExpenseTemplate.active.includes(:user)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy
    redirect_to admin_expenses_path, notice: "Expense was successfully deleted."
  end

  private

  def set_expense
    @expense = Expense.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:monthly_budget_id, :expense_template_id, :allotted_amount, :name)
  end
end

