# frozen_string_literal: true

class Admin::ExpenseTemplatesController < Admin::BaseController
  before_action :set_expense_template, only: [:show, :edit, :update, :destroy]

  def index
    @expense_templates = ExpenseTemplate.active.includes(:user).reorder(created_at: :desc)
    @total_templates = ExpenseTemplate.active.count
    @fixed_templates = ExpenseTemplate.active.fixed.count
    @variable_templates = ExpenseTemplate.active.variable.count
    @savings_templates = ExpenseTemplate.active.savings.count
  end

  def show
  end

  def new
    @expense_template = ExpenseTemplate.new
    @users = User.order(:email)
  end

  def create
    @expense_template = ExpenseTemplate.new(expense_template_params)
    if @expense_template.save
      redirect_to admin_expense_template_path(@expense_template), notice: "Expense template was successfully created."
    else
      @users = User.order(:email)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @users = User.order(:email)
  end

  def update
    if @expense_template.update(expense_template_params)
      redirect_to admin_expense_template_path(@expense_template), notice: "Expense template was successfully updated."
    else
      @users = User.order(:email)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Soft delete: set is_active to false instead of actually deleting
    @expense_template.update(is_active: false)
    redirect_to admin_expense_templates_path, notice: "Expense template was successfully deleted."
  end

  private

  def set_expense_template
    # Find templates even if they're inactive (for admin access to view/edit)
    @expense_template = ExpenseTemplate.find(params[:id])
  end

  def expense_template_params
    params.require(:expense_template).permit(:user_id, :name, :frequency, :due_date, :default_amount, :auto_create, :is_active)
  end
end

