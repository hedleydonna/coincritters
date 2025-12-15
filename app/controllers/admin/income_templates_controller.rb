# frozen_string_literal: true

class Admin::IncomeTemplatesController < Admin::BaseController
  before_action :set_income_template, only: [:show, :edit, :update, :destroy]

  def index
    @income_templates = IncomeTemplate.includes(:user).order(created_at: :desc)
    @total_income_templates = IncomeTemplate.count
    @active_income_templates = IncomeTemplate.active.count
    @auto_create_income_templates = IncomeTemplate.auto_create.count
  end

  def show
  end

  def edit
  end

  def update
    if @income_template.update(income_template_params)
      redirect_to admin_income_template_path(@income_template), notice: "Income template was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @income_template.destroy
    redirect_to admin_income_templates_path, notice: "Income template was successfully deleted."
  end

  private

  def set_income_template
    @income_template = IncomeTemplate.find(params[:id])
  end

  def income_template_params
    params.require(:income_template).permit(:name, :frequency, :estimated_amount, :active, :user_id, :auto_create, :due_date, :last_payment_to_next_month)
  end
end

