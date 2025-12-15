# frozen_string_literal: true

class Admin::IncomesController < Admin::BaseController
  before_action :set_income, only: [:show, :edit, :update, :destroy]

  def index
    @incomes = Income.includes(:user).order(created_at: :desc)
    @total_incomes = Income.count
    @active_incomes = Income.active.count
    @auto_create_incomes = Income.auto_create.count
  end

  def show
  end

  def edit
  end

  def update
    if @income.update(income_params)
      redirect_to admin_income_path(@income), notice: "Income was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @income.destroy
    redirect_to admin_incomes_path, notice: "Income was successfully deleted."
  end

  private

  def set_income
    @income = Income.find(params[:id])
  end

  def income_params
    params.require(:income).permit(:name, :frequency, :estimated_amount, :active, :user_id, :auto_create, :due_date, :last_payment_to_next_month)
  end
end

