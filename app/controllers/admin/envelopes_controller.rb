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
    @envelope_templates = EnvelopeTemplate.active.includes(:user)
  end

  def create
    @envelope = Envelope.new(envelope_params)
    if @envelope.save
      redirect_to admin_envelope_path(@envelope), notice: "Envelope was successfully created."
    else
      @monthly_budgets = MonthlyBudget.includes(:user).order(created_at: :desc)
      @envelope_templates = EnvelopeTemplate.active.includes(:user)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @monthly_budgets = MonthlyBudget.includes(:user).order(created_at: :desc)
    @envelope_templates = EnvelopeTemplate.active.includes(:user)
  end

  def update
    if @envelope.update(envelope_params)
      redirect_to admin_envelope_path(@envelope), notice: "Envelope was successfully updated."
    else
      @monthly_budgets = MonthlyBudget.includes(:user).order(created_at: :desc)
      @envelope_templates = EnvelopeTemplate.active.includes(:user)
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
    params.require(:envelope).permit(:monthly_budget_id, :envelope_template_id, :allotted_amount, :name)
  end
end

