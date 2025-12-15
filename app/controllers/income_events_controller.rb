# app/controllers/income_events_controller.rb
class IncomeEventsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_income_event, only: [:edit, :update, :mark_received, :toggle_defer, :destroy]

  def index
    # Allow viewing current or next month
    current_month_str = Time.current.strftime("%Y-%m")
    next_month_str = (Date.today + 1.month).strftime("%Y-%m")
    month_year = params[:month] || current_month_str
    
    # Only allow current or next month
    unless month_year == current_month_str || month_year == next_month_str
      redirect_to income_events_path, alert: "You can only view current or next month."
      return
    end
    
    # Get or create the budget for the viewing month
    if month_year == current_month_str
      @budget = current_user.current_budget!
      # Always regenerate income events for current month when visiting
      @budget.auto_create_income_events
    else
      # For next month, ensure budget exists
      unless current_user.monthly_budgets.exists?(month_year: next_month_str)
        current_user.create_next_month_budget!
      end
      @budget = current_user.monthly_budgets.find_by(month_year: next_month_str)
      @budget.auto_create_income_events if @budget
    end
    
    # Get income events for this month (including deferred from previous month)
    # Events count toward this month if: (month_year matches AND not deferred) OR (month_year is previous AND deferred)
    if month_year == current_month_str
      # Current month: show events from this month (not deferred) + deferred from previous month
      prev_month = (Date.parse("#{month_year}-01") - 1.month).strftime("%Y-%m")
      @income_events = current_user.income_events.where(
        "(month_year = ? AND apply_to_next_month = false) OR (month_year = ? AND apply_to_next_month = true)",
        month_year, prev_month
      ).order(:received_on)
    else
      # Next month: show events from next month (not deferred) + deferred from current month
      @income_events = current_user.income_events.where(
        "(month_year = ? AND apply_to_next_month = false) OR (month_year = ? AND apply_to_next_month = true)",
        month_year, current_month_str
      ).order(:received_on)
    end
    
    # Calculate totals for the viewing month
    @total_expected = @budget&.expected_income || 0
    @total_actual = @budget&.total_actual_income || 0
    
    # Month navigation helpers
    @current_month = current_month_str
    @next_month_str = next_month_str
    @viewing_month = month_year
    @is_current_month = @viewing_month == @current_month
    @is_next_month = @viewing_month == @next_month_str
  end

  def new
    # Check if editing an existing auto-created event
    if params[:income_event_id].present?
      @income_event = current_user.income_events.find_by(id: params[:income_event_id])
      if @income_event
        redirect_to edit_income_event_path(@income_event)
        return
      end
    end
    
    @income_event = current_user.income_events.new
    @income_event.received_on = Date.today # Default to today
    
    # Determine which month to apply to (default: current month)
    @apply_to_month = params[:apply_to] || "current"
    current_month_str = Time.current.strftime("%Y-%m")
    next_month_str = (Date.today + 1.month).strftime("%Y-%m")
    
    @current_month_str = current_month_str
    @next_month_str = next_month_str
  end

  def edit
    @incomes = current_user.incomes.active.order(:name)
    @income_data = @incomes.map { |i| [i.id.to_s, i.estimated_amount.to_f] }.to_h.to_json
  end

  def create
    @income_event = current_user.income_events.new(income_event_params)
    # Ensure income_id is nil for one-off events
    @income_event.income_id = nil
    # One-off income always counts in the month received (not deferred)
    @income_event.apply_to_next_month = false
    
    # Set month_year from received_on
    @income_event.month_year = @income_event.received_on.strftime("%Y-%m")
    
    if @income_event.save
      redirect_to income_events_path, notice: "Income logged! #{helpers.number_to_currency(@income_event.actual_amount)} added to your budget."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @incomes = current_user.incomes.active.order(:name)
    
    # Update month_year if received_on changed
    new_month_year = @income_event.received_on.strftime("%Y-%m")
    if params[:income_event][:received_on].present?
      new_month_year = Date.parse(params[:income_event][:received_on]).strftime("%Y-%m")
    end
    
    if @income_event.update(income_event_params.merge(month_year: new_month_year))
      redirect_to income_events_path, notice: "Income updated! #{helpers.number_to_currency(@income_event.actual_amount)}"
    else
      @incomes = current_user.incomes.active.order(:name)
      @income_data = @incomes.map { |i| [i.id.to_s, i.estimated_amount.to_f] }.to_h.to_json
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle_defer
    @income_event.update(apply_to_next_month: !@income_event.apply_to_next_month)
    status = @income_event.apply_to_next_month? ? "deferred to next month" : "counts in this month"
    redirect_to income_events_path, notice: "Income #{status}."
  end

  def destroy
    amount = @income_event.actual_amount
    @income_event.destroy
    redirect_to income_events_path, notice: "Income event removed. #{helpers.number_to_currency(amount)} has been removed from your budget."
  end

  def mark_received
    # Set actual_amount to estimated_amount from the income template
    if @income_event.income && @income_event.income.estimated_amount > 0
      @income_event.update(actual_amount: @income_event.income.estimated_amount)
      redirect_to income_events_path, notice: "Marked as received! #{helpers.number_to_currency(@income_event.actual_amount)}"
    else
      redirect_to income_events_path, alert: "Cannot mark as received - no expected amount set for this income source."
    end
  end

  private

  def set_income_event
    @income_event = current_user.income_events.find(params[:id])
  end

  def income_event_params
    # For new one-off events, don't allow income_id or apply_to_next_month
    # For editing existing events (which might be linked to templates), allow it
    if action_name == 'create'
      params.require(:income_event).permit(:custom_label, :received_on, :actual_amount, :notes)
    else
      params.require(:income_event).permit(:income_id, :custom_label, :received_on, :actual_amount, :notes, :apply_to_next_month)
    end
  end
end

