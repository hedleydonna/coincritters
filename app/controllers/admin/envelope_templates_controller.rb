# frozen_string_literal: true

class Admin::EnvelopeTemplatesController < Admin::BaseController
  before_action :set_envelope_template, only: [:show, :edit, :update, :destroy]

  def index
    @envelope_templates = EnvelopeTemplate.active.includes(:user).reorder(created_at: :desc)
    @total_templates = EnvelopeTemplate.active.count
    @fixed_templates = EnvelopeTemplate.active.fixed.count
    @variable_templates = EnvelopeTemplate.active.variable.count
    @savings_templates = EnvelopeTemplate.active.savings.count
  end

  def show
  end

  def new
    @envelope_template = EnvelopeTemplate.new
    @users = User.order(:email)
  end

  def create
    @envelope_template = EnvelopeTemplate.new(envelope_template_params)
    if @envelope_template.save
      redirect_to admin_envelope_template_path(@envelope_template), notice: "Envelope template was successfully created."
    else
      @users = User.order(:email)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @users = User.order(:email)
  end

  def update
    if @envelope_template.update(envelope_template_params)
      redirect_to admin_envelope_template_path(@envelope_template), notice: "Envelope template was successfully updated."
    else
      @users = User.order(:email)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Soft delete: set is_active to false instead of actually deleting
    @envelope_template.update(is_active: false)
    redirect_to admin_envelope_templates_path, notice: "Envelope template was successfully deleted."
  end

  private

  def set_envelope_template
    # Find templates even if they're inactive (for admin access to view/edit)
    @envelope_template = EnvelopeTemplate.find(params[:id])
  end

  def envelope_template_params
    params.require(:envelope_template).permit(:user_id, :name, :group_type, :is_savings, :default_amount, :auto_create, :is_active)
  end
end

