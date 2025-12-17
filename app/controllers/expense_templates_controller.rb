# app/controllers/expense_templates_controller.rb
class ExpenseTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_template, only: %i[edit update destroy]
  before_action :set_deleted_template, only: [:reactivate]

  def index
    @templates = current_user.expense_templates.active.order(:name)
    @return_to = params[:return_to] # 'expenses', 'settings', or nil
  end

  def new
    @template = current_user.expense_templates.new
    @return_to = params[:return_to]
  end

  def create
    @template = current_user.expense_templates.new(template_params)
    if @template.save
      # Always return to expense_templates index page after creating
      # The return_to parameter is preserved for navigation context
      redirect_to expense_templates_path(return_to: params[:return_to]), notice: "Spending item created!"
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
    @template.soft_delete!
    # Always stay on expense_templates page after deleting
    # The return_to parameter is preserved for navigation context
    redirect_to expense_templates_path(return_to: params[:return_to]), notice: "Spending item deleted. It will stop appearing in new months."
  end

  def reactivate
    @template.restore!
    redirect_path = if params[:return_to] == 'expenses'
      expenses_path
    else
      expense_templates_path(return_to: params[:return_to])
    end
    redirect_to redirect_path, notice: "Spending item restored!"
  end

  private

  def set_template
    @template = current_user.expense_templates.find(params[:id])
  end

  def set_deleted_template
    @template = current_user.expense_templates.with_deleted.find(params[:id])
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

