# app/controllers/income_templates_controller.rb
class IncomeTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_income_template, only: %i[edit update destroy]
  before_action :set_deleted_income_template, only: [:reactivate]

  def index
    @income_templates = current_user.income_templates.active.order(:name)
    @return_to = params[:return_to] # 'income_events', 'settings', or nil
  end

  def new
    @income_template = current_user.income_templates.new
    @income_template.frequency = "monthly"
    @income_template.auto_create = false
    @return_to = params[:return_to]
  end

  def create
    @income_template = current_user.income_templates.new(income_template_params)
    if @income_template.save
      # Always return to income_templates index page after creating
      # The return_to parameter is preserved for navigation context
      redirect_to income_templates_path(return_to: params[:return_to]), notice: "Money in source created!"
    else
      @return_to = params[:return_to]
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @return_to = params[:return_to]
  end

  def update
    if @income_template.update(income_template_params)
      redirect_path = if params[:return_to] == 'income_events'
        income_events_path
      else
        income_templates_path(return_to: params[:return_to])
      end
      redirect_to redirect_path, notice: "Income source updated!"
    else
      @return_to = params[:return_to]
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @income_template.soft_delete!
    # Always stay on income_templates page after deleting
    # The return_to parameter is preserved for navigation context
    redirect_to income_templates_path(return_to: params[:return_to]), notice: "Money in source deleted. It will stop creating events in new months."
  end

  def reactivate
    @income_template.restore!
    redirect_path = if params[:return_to] == 'income_events'
      income_events_path
    else
      income_templates_path(return_to: params[:return_to])
    end
    redirect_to redirect_path, notice: "Money in source restored!"
  end

  private

  def set_income_template
    @income_template = current_user.income_templates.find(params[:id])
  end

  def set_deleted_income_template
    @income_template = current_user.income_templates.with_deleted.find(params[:id])
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

