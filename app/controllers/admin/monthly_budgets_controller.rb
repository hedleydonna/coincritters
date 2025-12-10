# frozen_string_literal: true

class Admin::MonthlyBudgetsController < Admin::BaseController
  before_action :set_monthly_budget, only: [:show, :edit, :update, :destroy]

  def index
    @monthly_budgets = MonthlyBudget.includes(:user).order(created_at: :desc)
    @total_budgets = MonthlyBudget.count
  end

  def show
  end

  def new
    @monthly_budget = MonthlyBudget.new
    @users = User.all
  end

  def create
    @monthly_budget = MonthlyBudget.new(monthly_budget_params)
    if @monthly_budget.save
      redirect_to admin_monthly_budget_path(@monthly_budget), notice: "Monthly budget was successfully created."
    else
      @users = User.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @users = User.all
  end

  def update
    if @monthly_budget.update(monthly_budget_params)
      redirect_to admin_monthly_budget_path(@monthly_budget), notice: "Monthly budget was successfully updated."
    else
      @users = User.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @monthly_budget.destroy
    redirect_to admin_monthly_budgets_path, notice: "Monthly budget was successfully deleted."
  end

  private

  def set_monthly_budget
    @monthly_budget = MonthlyBudget.find(params[:id])
  end

  def monthly_budget_params
    params.require(:monthly_budget).permit(:user_id, :month_year, :total_actual_income, :flex_fund, :bank_balance)
  end
end

