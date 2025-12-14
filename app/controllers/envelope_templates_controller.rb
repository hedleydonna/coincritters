# app/controllers/envelope_templates_controller.rb
class EnvelopeTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_template, only: %i[edit update destroy reactivate]

  def index
    @templates = current_user.envelope_templates.active.order(:name)
    @inactive_templates = current_user.envelope_templates.inactive.order(:name)
  end

  def new
    @template = current_user.envelope_templates.new
  end

  def create
    @template = current_user.envelope_templates.new(template_params)
    if @template.save
      redirect_to envelope_templates_path, notice: "Branch created!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @template.update(template_params)
      redirect_to envelope_templates_path, notice: "Branch updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @template.deactivate!
      redirect_to envelope_templates_path, notice: "Branch turned off. It will stop appearing in new months."
  end

  def reactivate
    @template.activate!
      redirect_to envelope_templates_path, notice: "Branch turned back on!"
  end

  private

  def set_template
    @template = current_user.envelope_templates.find(params[:id])
  end

  def template_params
    params.require(:envelope_template).permit(
      :name,
      :default_amount,
      :group_type,
      :is_savings,
      :auto_create
    )
  end
end

