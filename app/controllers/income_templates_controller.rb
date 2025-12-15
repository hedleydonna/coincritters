# app/controllers/income_templates_controller.rb
class IncomeTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_income_template, only: %i[edit update destroy reactivate]

  def index
    @income_templates = current_user.income_templates.active.order(:name)
    @inactive_income_templates = current_user.income_templates.where(active: false).order(:name)
  end

  def new
    @income_template = current_user.income_templates.new
    @income_template.frequency = "monthly"
    @income_template.auto_create = false
  end

  def create
    @income_template = current_user.income_templates.new(income_template_params)
    if @income_template.save
      redirect_to income_templates_path, notice: "Income source created!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @income_template.update(income_template_params)
      redirect_to income_templates_path, notice: "Income source updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @income_template.update(active: false)
    redirect_to income_templates_path, notice: "Income source turned off. It will stop creating events in new months."
  end

  def reactivate
    @income_template.update(active: true)
    redirect_to income_templates_path, notice: "Income source turned back on!"
  end

  private

  def set_income_template
    @income_template = current_user.income_templates.find(params[:id])
  end

  def income_template_params
    params.require(:income_template).permit(
      :name,
      :frequency,
      :due_date,
      :estimated_amount,
      :auto_create,
      :active,
      :last_payment_to_next_month
    )
  end
end

