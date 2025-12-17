# app/controllers/expense_templates_controller.rb
class ExpenseTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_template, only: %i[edit update destroy reactivate]

  def index
    @templates = current_user.expense_templates.active.order(:name)
    @inactive_templates = current_user.expense_templates.inactive.order(:name)
    @return_to = params[:return_to] # 'expenses', 'settings', or nil
  end

  def new
    @template = current_user.expense_templates.new
    @return_to = params[:return_to]
  end

  def create
    @template = current_user.expense_templates.new(template_params)
    if @template.save
      redirect_path = if params[:return_to] == 'expenses'
        expenses_path
      else
        expense_templates_path(return_to: params[:return_to])
      end
      redirect_to redirect_path, notice: "Branch created!"
    else
      @return_to = params[:return_to]
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @return_to = params[:return_to]
  end

  def update
    if @template.update(template_params)
      redirect_path = if params[:return_to] == 'expenses'
        expenses_path
      else
        expense_templates_path(return_to: params[:return_to])
      end
      redirect_to redirect_path, notice: "Branch updated!"
    else
      @return_to = params[:return_to]
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @template.deactivate!
    redirect_path = if params[:return_to] == 'expenses'
      expenses_path
    else
      expense_templates_path(return_to: params[:return_to])
    end
    redirect_to redirect_path, notice: "Branch turned off. It will stop appearing in new months."
  end

  def reactivate
    @template.activate!
    redirect_path = if params[:return_to] == 'expenses'
      expenses_path
    else
      expense_templates_path(return_to: params[:return_to])
    end
    redirect_to redirect_path, notice: "Branch turned back on!"
  end

  private

  def set_template
    @template = current_user.expense_templates.find(params[:id])
  end

  def template_params
    params.require(:expense_template).permit(
      :name,
      :frequency,
      :due_date,
      :default_amount,
      :auto_create
    )
  end
end

