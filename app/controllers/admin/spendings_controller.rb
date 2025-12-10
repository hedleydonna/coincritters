# frozen_string_literal: true

class Admin::SpendingsController < Admin::BaseController
  before_action :set_spending, only: [:show, :edit, :update, :destroy]

  def index
    @spendings = Spending.includes(envelope: { monthly_budget: :user }).recent
    @total_spendings = Spending.count
    @total_amount = Spending.sum(:amount)
  end

  def show
  end

  def new
    @spending = Spending.new
    @envelopes = Envelope.includes(monthly_budget: :user).order(created_at: :desc)
  end

  def create
    @spending = Spending.new(spending_params)
    if @spending.save
      redirect_to admin_spending_path(@spending), notice: "Spending was successfully created."
    else
      @envelopes = Envelope.includes(monthly_budget: :user).order(created_at: :desc)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @envelopes = Envelope.includes(monthly_budget: :user).order(created_at: :desc)
  end

  def update
    if @spending.update(spending_params)
      redirect_to admin_spending_path(@spending), notice: "Spending was successfully updated."
    else
      @envelopes = Envelope.includes(monthly_budget: :user).order(created_at: :desc)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @spending.destroy
    redirect_to admin_spendings_path, notice: "Spending was successfully deleted."
  end

  private

  def set_spending
    @spending = Spending.find(params[:id])
  end

  def spending_params
    params.require(:spending).permit(:envelope_id, :amount, :spent_on, :notes)
  end
end

