# app/controllers/incomes_controller.rb
class IncomesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_income, only: %i[edit update destroy reactivate]

  def index
    @incomes = current_user.incomes.active.order(:name)
    @inactive_incomes = current_user.incomes.where(active: false).order(:name)
  end

  def new
    @income = current_user.incomes.new
    @income.frequency = "monthly"
    @income.auto_create = false
  end

  def create
    @income = current_user.incomes.new(income_params)
    if @income.save
      redirect_to incomes_path, notice: "Income source created!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @income.update(income_params)
      redirect_to incomes_path, notice: "Income source updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @income.update(active: false)
    redirect_to incomes_path, notice: "Income source turned off. It will stop creating events in new months."
  end

  def reactivate
    @income.update(active: true)
    redirect_to incomes_path, notice: "Income source turned back on!"
  end

  private

  def set_income
    @income = current_user.incomes.find(params[:id])
  end

  def income_params
    params.require(:income).permit(
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

