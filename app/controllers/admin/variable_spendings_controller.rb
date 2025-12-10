# frozen_string_literal: true

class Admin::VariableSpendingsController < Admin::BaseController
  before_action :set_variable_spending, only: [:show, :edit, :update, :destroy]

  def index
    @variable_spendings = VariableSpending.includes(envelope: { monthly_budget: :user }).recent
    @total_spendings = VariableSpending.count
    @total_amount = VariableSpending.sum(:amount)
  end

  def show
  end

  def new
    @variable_spending = VariableSpending.new
    @envelopes = Envelope.includes(monthly_budget: :user).variable.order(created_at: :desc)
  end

  def create
    @variable_spending = VariableSpending.new(variable_spending_params)
    if @variable_spending.save
      redirect_to admin_variable_spending_path(@variable_spending), notice: "Variable spending was successfully created."
    else
      @envelopes = Envelope.includes(monthly_budget: :user).variable.order(created_at: :desc)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @envelopes = Envelope.includes(monthly_budget: :user).variable.order(created_at: :desc)
  end

  def update
    if @variable_spending.update(variable_spending_params)
      redirect_to admin_variable_spending_path(@variable_spending), notice: "Variable spending was successfully updated."
    else
      @envelopes = Envelope.includes(monthly_budget: :user).variable.order(created_at: :desc)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @variable_spending.destroy
    redirect_to admin_variable_spendings_path, notice: "Variable spending was successfully deleted."
  end

  private

  def set_variable_spending
    @variable_spending = VariableSpending.find(params[:id])
  end

  def variable_spending_params
    params.require(:variable_spending).permit(:envelope_id, :spending_group_name, :amount, :spent_on, :notes)
  end
end

