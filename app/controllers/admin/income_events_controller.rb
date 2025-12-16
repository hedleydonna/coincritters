# frozen_string_literal: true

class Admin::IncomeEventsController < Admin::BaseController
  before_action :set_income_event, only: [:show, :edit, :update, :destroy]

  def index
    @income_events = IncomeEvent.includes(:user, :income_template).order(created_at: :desc)
    @total_income_events = IncomeEvent.count
  end

  def show
  end

  def new
    @income_event = IncomeEvent.new
    @users = User.all # For dropdown to assign income event to a user
    @income_templates = IncomeTemplate.all # For dropdown to assign income event to an income template
  end

  def create
    @income_event = IncomeEvent.new(income_event_params)
    if @income_event.save
      redirect_to admin_income_event_path(@income_event), notice: "Income event was successfully created."
    else
      @users = User.all # Re-fetch for rendering new form on error
      @income_templates = IncomeTemplate.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @users = User.all # For dropdown to assign income event to a user
    @income_templates = IncomeTemplate.all # For dropdown to assign income event to an income template
  end

  def update
    if @income_event.update(income_event_params)
      redirect_to admin_income_event_path(@income_event), notice: "Income event was successfully updated."
    else
      @users = User.all # Re-fetch for rendering edit form on error
      @income_templates = IncomeTemplate.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @income_event.destroy
    redirect_to admin_income_events_path, notice: "Income event was successfully deleted."
  end

  private

  def set_income_event
    @income_event = IncomeEvent.find(params[:id])
  end

  def income_event_params
    params.require(:income_event).permit(:user_id, :income_template_id, :custom_label, :month_year, :apply_to_next_month, :received_on, :actual_amount, :notes)
  end
end

