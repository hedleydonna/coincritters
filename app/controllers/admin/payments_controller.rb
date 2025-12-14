# frozen_string_literal: true

class Admin::PaymentsController < Admin::BaseController
  before_action :set_payment, only: [:show, :edit, :update, :destroy]

  def index
    @payments = Payment.includes(expense: { monthly_budget: :user }).recent
    @total_payments = Payment.count
    @total_amount = Payment.sum(:amount)
  end

  def show
  end

  def new
    @payment = Payment.new
    @expenses = Expense.includes(monthly_budget: :user).order(created_at: :desc)
  end

  def create
    @payment = Payment.new(payment_params)
    if @payment.save
      redirect_to admin_payment_path(@payment), notice: "Payment was successfully created."
    else
      @expenses = Expense.includes(monthly_budget: :user).order(created_at: :desc)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @expenses = Expense.includes(monthly_budget: :user).order(created_at: :desc)
  end

  def update
    if @payment.update(payment_params)
      redirect_to admin_payment_path(@payment), notice: "Payment was successfully updated."
    else
      @expenses = Expense.includes(monthly_budget: :user).order(created_at: :desc)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @payment.destroy
    redirect_to admin_payments_path, notice: "Payment was successfully deleted."
  end

  private

  def set_payment
    @payment = Payment.find(params[:id])
  end

  def payment_params
    params.require(:payment).permit(:expense_id, :amount, :spent_on, :notes)
  end
end

