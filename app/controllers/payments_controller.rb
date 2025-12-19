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

  def destroy
    @payment = Payment.find(params[:id])
    expense = @payment.expense
    
    # Ensure the payment belongs to the user
    unless expense.user == current_user
      redirect_to expenses_path, alert: "Payment not found."
      return
    end
    
    # Get return_to parameter for redirect
    return_to = params[:return_to]
    expense_id = expense.id
    
    @payment.destroy
    
    # Redirect back to expense edit page if return_to is provided, otherwise to expenses index
    if return_to.present?
      redirect_to edit_expense_path(expense, return_to: return_to), notice: "Payment deleted.", status: :see_other
    else
      redirect_to expenses_path(month: expense.monthly_budget.month_year), notice: "Payment deleted.", status: :see_other
    end
  end

  private

  def payment_params
    params.require(:payment).permit(:expense_id, :amount, :spent_on, :notes)
  end
end

