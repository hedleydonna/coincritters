# app/controllers/payments_controller.rb
class PaymentsController < ApplicationController
  before_action :authenticate_user!

  def new
    # Allow creating payment for a specific month, otherwise current month
    month_year = params[:month] || Time.current.strftime("%Y-%m")
    @budget = current_user.monthly_budgets.find_by(month_year: month_year) || current_user.current_budget!
    @payment = Payment.new
    @payment.spent_on = Date.today # Default to today
    @viewing_month = @budget.month_year
    
    # If expense_id is provided, pre-select it
    if params[:expense_id].present?
      @payment.expense_id = params[:expense_id]
      @expenses = @budget.expenses.where(id: params[:expense_id])
    else
      @expenses = @budget.expenses.order(:name)
    end
  end

  def create
    month_year = params[:month] || Time.current.strftime("%Y-%m")
    @budget = current_user.monthly_budgets.find_by(month_year: month_year) || current_user.current_budget!
    @payment = Payment.new(payment_params)
    @viewing_month = @budget.month_year
    
    # Ensure the expense belongs to the user's budget
    unless @budget.expenses.exists?(@payment.expense_id)
      @payment.errors.add(:expense, "must belong to your budget")
      @expenses = @budget.expenses.order(:name)
      render :new, status: :unprocessable_entity
      return
    end
    
    if @payment.save
      redirect_to expenses_path(month: @budget.month_year), notice: "Payment added!"
    else
      @expenses = @budget.expenses.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def payment_params
    params.require(:payment).permit(:expense_id, :amount, :spent_on, :notes)
  end
end

