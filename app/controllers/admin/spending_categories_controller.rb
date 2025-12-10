# frozen_string_literal: true

class Admin::SpendingCategoriesController < Admin::BaseController
  before_action :set_spending_category, only: [:show, :edit, :update, :destroy]

  def index
    @spending_categories = SpendingCategory.includes(:user).order(created_at: :desc)
    @total_categories = SpendingCategory.count
    @fixed_categories = SpendingCategory.fixed.count
    @variable_categories = SpendingCategory.variable.count
    @savings_categories = SpendingCategory.savings.count
  end

  def show
  end

  def new
    @spending_category = SpendingCategory.new
    @users = User.order(:email)
  end

  def create
    @spending_category = SpendingCategory.new(spending_category_params)
    if @spending_category.save
      redirect_to admin_spending_category_path(@spending_category), notice: "Spending category was successfully created."
    else
      @users = User.order(:email)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @users = User.order(:email)
  end

  def update
    if @spending_category.update(spending_category_params)
      redirect_to admin_spending_category_path(@spending_category), notice: "Spending category was successfully updated."
    else
      @users = User.order(:email)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @spending_category.destroy
    redirect_to admin_spending_categories_path, notice: "Spending category was successfully deleted."
  end

  private

  def set_spending_category
    @spending_category = SpendingCategory.find(params[:id])
  end

  def spending_category_params
    params.require(:spending_category).permit(:user_id, :name, :group_type, :is_savings, :default_amount, :auto_create)
  end
end

