# app/controllers/income_events_controller.rb
class IncomeEventsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_income_event, only: [:show, :edit, :update, :mark_received, :reset_to_expected, :destroy]

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
    
    # Get income events for this month (no defer logic - use automatic carryover instead)
    # Only show events from active (non-deleted) templates, or one-off events (no template)
    @income_events = current_user.income_events
      .joins("LEFT JOIN income_templates ON income_events.income_template_id = income_templates.id")
      .where(
        "month_year = ? AND apply_to_next_month = false AND (income_templates.deleted_at IS NULL OR income_templates.id IS NULL)",
        month_year
      )
      .order(:received_on)
    
    # Calculate totals for the viewing month
    @total_expected = @budget&.expected_income || 0
    @total_actual = @budget&.total_actual_income || 0
    @carryover = @budget&.carryover_from_previous_month || 0.0
    @available_income = @budget&.available_income || 0.0
    
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
    @return_to = params[:return_to]
  end

  def show
    # Quick action page - only show if not yet received and has template with estimated amount
    @return_to = params[:return_to]
    
    # If already received, no template, or no estimated amount, redirect to edit
    if @income_event.actual_amount > 0 || 
       @income_event.income_template.nil? || 
       @income_event.income_template.estimated_amount.to_f == 0
      redirect_to edit_income_event_path(@income_event, return_to: @return_to)
    end
  end

  def edit
    # Template selection removed - income events keep their original template association (or remain custom)
    @return_to = params[:return_to]
  end

  def create
    # Check if user wants to create a recurring template (frequency is not "just_once")
    if params[:frequency].present? && params[:frequency] != "just_once"
      # Create template and event
      @income_template = current_user.income_templates.new(
        name: params[:income_event][:custom_label],
        frequency: params[:frequency],
        due_date: params[:due_date],
        estimated_amount: params[:estimated_amount].present? ? params[:estimated_amount] : 0,
        auto_create: true  # Always true when creating through this form
      )
      
      if @income_template.save
        # Create the income event linked to the template
        event_params = income_event_params.dup
        # For recurring templates, use due_date as received_on
        received_on_date = if params[:due_date].present?
          Date.parse(params[:due_date])
        else
          Date.today
        end
        event_params[:received_on] ||= received_on_date
        
        @income_event = current_user.income_events.new(event_params)
        @income_event.income_template_id = @income_template.id
        # Only set actual_amount if the received_on date is today (not in the future)
        # This matches the logic in auto_create_income_events
        @income_event.actual_amount = if received_on_date == Date.today
          @income_template.estimated_amount || 0
        else
          0
        end
        @income_event.apply_to_next_month = false
        @income_event.month_year = @income_event.received_on.strftime("%Y-%m")
        
        if @income_event.save
          redirect_path = case params[:return_to]
                          when 'money_map'
                            money_map_path
                          when 'income_templates'
                            income_templates_path(return_to: params[:return_to])
                          else
                            income_events_path
                          end
          redirect_to redirect_path, notice: "Recurring income source created! #{helpers.number_to_currency(@income_event.actual_amount)} added to your budget. Events will be automatically created each month."
        else
          # If event creation fails, delete the template and show errors
          @income_template.destroy
          @return_to = params[:return_to]
          # Preserve params for form re-render
          @preserved_params = {
            frequency: params[:frequency],
            due_date: params[:due_date],
            estimated_amount: params[:estimated_amount]
          }
          render :new, status: :unprocessable_entity
        end
      else
        # Template validation failed - create a temporary income_event for error display
        @income_event = current_user.income_events.new(income_event_params)
        @income_event.errors.add(:base, "Template creation failed")
        @income_template.errors.full_messages.each do |message|
          @income_event.errors.add(:base, message)
        end
        @return_to = params[:return_to]
        # Preserve params for form re-render
        @preserved_params = {
          frequency: params[:frequency],
          due_date: params[:due_date],
          estimated_amount: params[:estimated_amount]
        }
        render :new, status: :unprocessable_entity
      end
    else
      # Create one-off income event only
    @income_event = current_user.income_events.new(income_event_params)
    # Ensure income_template_id is nil for one-off events
    @income_event.income_template_id = nil
      # Defer functionality removed - use automatic carryover instead
    @income_event.apply_to_next_month = false
    
    # Set month_year from received_on
    @income_event.month_year = @income_event.received_on.strftime("%Y-%m")
    
    if @income_event.save
        redirect_path = case params[:return_to]
                        when 'money_map'
                          money_map_path
                        when 'income_templates'
                          income_templates_path(return_to: params[:return_to])
                        else
                          income_events_path
                        end
        redirect_to redirect_path, notice: "Income logged! #{helpers.number_to_currency(@income_event.actual_amount)} added to your budget."
    else
        @return_to = params[:return_to]
      render :new, status: :unprocessable_entity
    end
    end
  rescue => e
    # Handle any unexpected errors
    Rails.logger.error "Income event creation error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    @income_event = current_user.income_events.new(income_event_params)
    @income_event.errors.add(:base, "An error occurred: #{e.message}")
    @return_to = params[:return_to]
    render :new, status: :unprocessable_entity
  end

  def update
    # Update month_year based on received_on from params
    update_params = income_event_params.dup
    
    # Calculate month_year from received_on if it's being updated
    # received_on comes as a string from the form, so we need to parse it
    if update_params[:received_on].present?
      begin
        received_date = update_params[:received_on].is_a?(String) ? Date.parse(update_params[:received_on]) : update_params[:received_on]
        new_month_year = received_date.strftime("%Y-%m")
        update_params[:month_year] = new_month_year
      rescue => e
        Rails.logger.error "Error parsing received_on: #{e.message}"
        # If date parsing fails, keep the existing month_year
      end
    end
    
    if @income_event.update(update_params)
      redirect_path = case params[:return_to]
                      when 'money_map'
                        money_map_path(scroll_to: 'money-in-section')
                      when 'income_templates'
                        income_templates_path(return_to: params[:return_to])
                      else
                        income_events_path
                      end
      redirect_to redirect_path, notice: "Income updated! #{helpers.number_to_currency(@income_event.actual_amount)}", status: :see_other
    else
      @return_to = params[:return_to]
      render :edit, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Error updating income event: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    @return_to = params[:return_to]
    @income_event.errors.add(:base, "An error occurred: #{e.message}")
    render :edit, status: :unprocessable_entity
  end

  def destroy
    # Only allow deletion of one-off income events (no template)
    unless @income_event.income_template_id.nil?
      redirect_to income_events_path, 
                  alert: "Cannot delete income events created from templates. Edit the template or set the amount to $0 instead."
      return
    end
    
    amount = @income_event.actual_amount
    @income_event.destroy
    redirect_to income_events_path, 
                notice: "Income event removed. #{helpers.number_to_currency(amount)} has been removed from your budget."
  end

  def mark_received
    # Set actual_amount to estimated_amount from the income template
    unless @income_event.income_template && @income_event.income_template.estimated_amount > 0
      redirect_path = case params[:return_to]
                      when 'money_map'
                        money_map_path(scroll_to: 'money-in-section')
                      else
                        income_events_path
                      end
      redirect_to redirect_path, alert: "Cannot mark as received - no expected amount set for this income source.", status: :see_other
      return
    end
    
    estimated_amount = @income_event.income_template.estimated_amount
    
    # Use update! to ensure it saves and raises an error if it fails
    # This will trigger validations and callbacks properly
    @income_event.actual_amount = estimated_amount
    
    if @income_event.save
      redirect_path = case params[:return_to]
                      when 'money_map'
                        money_map_path(scroll_to: 'money-in-section')
                      else
                        income_events_path
                      end
      redirect_to redirect_path, notice: "Marked as received! #{helpers.number_to_currency(estimated_amount)}", status: :see_other
    else
      # If save fails, show errors
      redirect_path = case params[:return_to]
                      when 'money_map'
                        money_map_path(scroll_to: 'money-in-section')
                      else
                        income_events_path
                      end
      error_message = @income_event.errors.full_messages.join(", ")
      redirect_to redirect_path, alert: "Failed to mark as received: #{error_message}", status: :see_other
    end
  end

  def reset_to_expected
    # Reset actual_amount to 0 (if funds are delayed)
    @income_event.update(actual_amount: 0)
    redirect_path = case params[:return_to]
                    when 'money_map'
                      money_map_path(scroll_to: 'money-in-section')
                    else
                      income_events_path
                    end
    redirect_to redirect_path, notice: "Reset to expected amount. Actual amount set to $0.00.", status: :see_other
  end

  private

  def set_income_event
    @income_event = current_user.income_events.includes(:income_template).find(params[:id])
    # Load template even if soft-deleted (for display purposes)
    if @income_event.income_template_id.present? && @income_event.income_template.nil?
      @income_event.association(:income_template).target ||= 
        IncomeTemplate.unscoped.find_by(id: @income_event.income_template_id)
    end
  end

  def income_event_params
    # Defer functionality removed - apply_to_next_month is no longer user-editable
    # For new one-off events, don't allow income_template_id
    # For editing existing events, don't allow changing income_template_id (it stays as originally set)
    if action_name == 'create'
      params.require(:income_event).permit(:custom_label, :received_on, :actual_amount, :notes)
    else
      params.require(:income_event).permit(:custom_label, :received_on, :actual_amount, :notes)
    end
  end
end

