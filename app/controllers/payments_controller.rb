# app/controllers/payments_controller.rb
class PaymentsController < ApplicationController
  before_action :authenticate_user!

  def new
    @budget = current_user.current_budget!
    @payment = Payment.new
    @payment.spent_on = Date.today # Default to today
    
    # If expense_id is provided, pre-select it
    if params[:expense_id].present?
      @payment.expense_id = params[:expense_id]
      @expenses = @budget.expenses.where(id: params[:expense_id])
    else
      @expenses = @budget.expenses.order(:name)
    end
  end

  def create
    @budget = current_user.current_budget!
    @payment = Payment.new(payment_params)
    
    # Ensure the expense belongs to the user's current budget
    unless @budget.expenses.exists?(@payment.expense_id)
      @payment.errors.add(:expense, "must belong to your current budget")
      @expenses = @budget.expenses.order(:name)
      render :new, status: :unprocessable_entity
      return
    end
    
    if @payment.save
      redirect_to expenses_path, notice: "Payment added!"
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

