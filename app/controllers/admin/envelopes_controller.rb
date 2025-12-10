# frozen_string_literal: true

class Admin::EnvelopesController < Admin::BaseController
  before_action :set_envelope, only: [:show, :edit, :update, :destroy]

  def index
    @envelopes = Envelope.includes(monthly_budget: :user).order(created_at: :desc)
    @total_envelopes = Envelope.count
  end

  def show
  end

  def new
    @envelope = Envelope.new
    @monthly_budgets = MonthlyBudget.includes(:user).order(created_at: :desc)
  end

  def create
    @envelope = Envelope.new(envelope_params)
    if @envelope.save
      redirect_to admin_envelope_path(@envelope), notice: "Envelope was successfully created."
    else
      @monthly_budgets = MonthlyBudget.includes(:user).order(created_at: :desc)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @monthly_budgets = MonthlyBudget.includes(:user).order(created_at: :desc)
  end

  def update
    if @envelope.update(envelope_params)
      redirect_to admin_envelope_path(@envelope), notice: "Envelope was successfully updated."
    else
      @monthly_budgets = MonthlyBudget.includes(:user).order(created_at: :desc)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @envelope.destroy
    redirect_to admin_envelopes_path, notice: "Envelope was successfully deleted."
  end

  private

  def set_envelope
    @envelope = Envelope.find(params[:id])
  end

  def envelope_params
    params.require(:envelope).permit(:monthly_budget_id, :spending_group_name, :group_type, :is_savings, :allotted_amount, :spent_amount)
  end
end

