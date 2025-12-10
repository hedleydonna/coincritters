# frozen_string_literal: true

class Admin::BillPaymentsController < Admin::BaseController
  before_action :set_bill_payment, only: [:show, :edit, :update, :destroy]

  def index
    @bill_payments = BillPayment.includes(envelope: { monthly_budget: :user }).recent
    @total_payments = BillPayment.count
    @total_amount = BillPayment.sum(:actual_paid_amount)
  end

  def show
  end

  def new
    @bill_payment = BillPayment.new
    @envelopes = Envelope.includes(monthly_budget: :user).fixed.order(spending_group_name: :asc)
  end

  def create
    @bill_payment = BillPayment.new(bill_payment_params)
    if @bill_payment.save
      redirect_to admin_bill_payment_path(@bill_payment), notice: "Bill payment was successfully created."
    else
      @envelopes = Envelope.includes(monthly_budget: :user).fixed.order(spending_group_name: :asc)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @envelopes = Envelope.includes(monthly_budget: :user).fixed.order(spending_group_name: :asc)
  end

  def update
    if @bill_payment.update(bill_payment_params)
      redirect_to admin_bill_payment_path(@bill_payment), notice: "Bill payment was successfully updated."
    else
      @envelopes = Envelope.includes(monthly_budget: :user).fixed.order(spending_group_name: :asc)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @bill_payment.destroy
    redirect_to admin_bill_payments_path, notice: "Bill payment was successfully deleted."
  end

  private

  def set_bill_payment
    @bill_payment = BillPayment.find(params[:id])
  end

  def bill_payment_params
    params.require(:bill_payment).permit(:envelope_id, :actual_paid_amount, :paid_on, :notes)
  end
end

