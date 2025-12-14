# app/controllers/payments_controller.rb
class PaymentsController < ApplicationController
  before_action :authenticate_user!

  def new
    # Only allow creating payments for current month
    current_month = Time.current.strftime("%Y-%m")
    month_year = params[:month] || current_month
    
    # Prevent payments for future or past months
    if month_year != current_month
      redirect_to expenses_path(month: month_year), alert: "Payments can only be added to the current month."
      return
    end
    
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
    current_month = Time.current.strftime("%Y-%m")
    month_year = params[:month] || current_month
    
    # Prevent payments for future or past months
    if month_year != current_month
      redirect_to expenses_path(month: month_year), alert: "Payments can only be added to the current month."
      return
    end
    
    @budget = current_user.monthly_budgets.find_by(month_year: month_year) || current_user.current_budget!
    @payment = Payment.new(payment_params)
    @viewing_month = @budget.month_year
    
    # Ensure the expense belongs to the user's budget and is in the current month
    unless @budget.month_year == current_month && @budget.expenses.exists?(@payment.expense_id)
      @payment.errors.add(:expense, "must belong to your current month budget")
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

