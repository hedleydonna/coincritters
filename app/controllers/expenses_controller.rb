# app/controllers/expenses_controller.rb
class ExpensesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_expense, only: [:mark_paid, :edit, :update, :destroy, :add_payment]

  def index
    # Auto-create current and next month if they don't exist
    current_month_str = Time.current.strftime("%Y-%m")
    next_month_str = (Date.today + 1.month).strftime("%Y-%m")
    
    # Ensure current month exists
    current_budget = current_user.current_budget!
    # Always regenerate income events for current month when visiting Money Map
    current_budget.auto_create_income_events
    # Always regenerate expenses from templates for current month
    current_budget.auto_create_expenses
    
    # Ensure next month exists
    unless current_user.monthly_budgets.exists?(month_year: next_month_str)
      current_user.create_next_month_budget!
    end
    
    # Allow viewing a specific month via params, otherwise show current month
    month_year = params[:month] || current_month_str
    
    @budget = current_user.monthly_budgets.find_by(month_year: month_year)
    
    # Also auto-create expenses for the month being viewed (if it's current or next month)
    if @budget && (month_year == current_month_str || month_year == next_month_str)
      @budget.auto_create_expenses
    end
    
    unless @budget
      # If trying to view a past month that doesn't exist, redirect to current
      if month_year < current_month_str
        redirect_to expenses_path, alert: "That month's budget doesn't exist."
        return
      else
        # For future months, just redirect to current
        redirect_to expenses_path
        return
      end
    end
    
    # Only show expenses from active (non-deleted) templates, or one-off expenses (no template)
    # Use with_deleted to access deleted templates for the join, then filter them out
    @expenses = @budget.expenses
      .joins("LEFT JOIN expense_templates ON expenses.expense_template_id = expense_templates.id")
      .where("expense_templates.deleted_at IS NULL OR expense_templates.id IS NULL")
      .order(:name)

    # For the expenses summary (expenses-focused, includes carryover)
    @total_spent = @budget.total_spent
    @available_income = @budget.available_income.to_f
    @carryover = @budget.carryover_from_previous_month.to_f
    @remaining = @budget.available_income.to_f - @budget.total_spent.to_f
    @bank_match = @budget.bank_match?
    @bank_difference = @budget.bank_difference

    # Month navigation helpers
    @current_month = current_month_str
    @next_month_str = next_month_str
    @viewing_month = @budget.month_year
    
    # Determine if viewing current, next, or past month
    @is_current_month = @viewing_month == @current_month
    @is_next_month = @viewing_month == @next_month_str
    @is_past_month = @viewing_month < @current_month
    
    # Get current and next month budgets for tab navigation
    @current_budget = current_user.monthly_budgets.find_by(month_year: @current_month)
    @next_budget = current_user.monthly_budgets.find_by(month_year: @next_month_str)
    
    # Get all past months for dropdown
    @past_months = current_user.monthly_budgets.where("month_year < ?", @current_month).order(month_year: :desc).pluck(:month_year)
  end

  def new
    # Allow creating expense for a specific month, otherwise current month
    month_year = params[:month] || Time.current.strftime("%Y-%m")
    @budget = current_user.monthly_budgets.find_by(month_year: month_year) || current_user.current_budget!
    @expense = @budget.expenses.new
    @viewing_month = @budget.month_year
    @return_to = params[:return_to]
  end

  def create
    # Check if user wants to create a recurring template (frequency is not "just_once")
    if params[:frequency].present? && params[:frequency] != "just_once"
      # Normalize frequency value (bi_weekly -> biweekly)
      normalized_frequency = params[:frequency]
      normalized_frequency = "biweekly" if normalized_frequency == "bi_weekly"
      
      # Create template and expense
      @expense_template = current_user.expense_templates.new(
        name: params[:expense][:name],
        frequency: normalized_frequency,
        due_date: params[:due_date],
        default_amount: params[:default_amount].present? ? params[:default_amount] : 0,
        auto_create: true  # Always true when creating through this form
      )
      
      if @expense_template.save
        # Auto-create all expenses for the current month based on frequency
        month_year = params[:month] || Time.current.strftime("%Y-%m")
        @budget = current_user.monthly_budgets.find_by(month_year: month_year) || current_user.current_budget!
        
        # Get all due dates for this month based on frequency and due_date
        event_dates = @expense_template.events_for_month(month_year)
        
        # For current month, only create expenses from today forward
        # For future months, create all expenses
        current_month_str = Time.current.strftime("%Y-%m")
        if month_year == current_month_str
          event_dates = event_dates.select { |date| date >= Date.today }
        end
        
        # Count how many expenses we currently have for this template
        current_count = @budget.expenses.where(expense_template_id: @expense_template.id).count
        expected_count = event_dates.count
        
        # Create expenses until we have the expected number
        # Each expense gets its own expected_on date from the event_dates array
        event_dates.each_with_index do |expected_date, index|
          # Skip if we've already created enough expenses
          next if current_count >= expected_count
          
          @budget.expenses.create!(
            expense_template: @expense_template,
            name: @expense_template.name,  # Copy template name to expense
            allotted_amount: @expense_template.default_amount || 0,
            expected_on: expected_date
          )
          current_count += 1
        end
        
        # Count how many expenses were created
        created_count = @budget.expenses.where(expense_template_id: @expense_template.id).count
        
        redirect_path = case params[:return_to]
                        when 'money_map'
                          money_map_path(scroll_to: 'spending-section')
                        else
                          expenses_path(month: @budget.month_year)
                        end
        
        if created_count > 1
          redirect_to redirect_path, notice: "Recurring spending template created! #{created_count} expense#{'s' if created_count != 1} added to your budget for this month. Expenses will be automatically created each month.", status: :see_other
        else
          redirect_to redirect_path, notice: "Recurring spending template created! Expense added to your budget. Expenses will be automatically created each month.", status: :see_other
        end
      else
        # Template validation failed
        month_year = params[:month] || Time.current.strftime("%Y-%m")
        @budget = current_user.monthly_budgets.find_by(month_year: month_year) || current_user.current_budget!
        @expense = @budget.expenses.new(expense_params)
        @expense.errors.add(:base, "Template creation failed")
        @expense_template.errors.full_messages.each do |message|
          @expense.errors.add(:base, message)
        end
        @viewing_month = @budget.month_year
        @return_to = params[:return_to]
        # Preserve params for form re-render
        @preserved_params = {
          frequency: params[:frequency],
          due_date: params[:due_date],
          default_amount: params[:default_amount]
        }
        render :new, status: :unprocessable_entity
      end
    else
      # Create one-off expense only
      month_year = params[:month] || Time.current.strftime("%Y-%m")
      @budget = current_user.monthly_budgets.find_by(month_year: month_year) || current_user.current_budget!
      @expense = @budget.expenses.new(expense_params)
      # Ensure expense_template_id is nil for one-off expenses
      @expense.expense_template_id = nil
      
      if @expense.save
        redirect_path = case params[:return_to]
                        when 'money_map'
                          money_map_path(scroll_to: 'spending-section')
                        else
                          expenses_path(month: @budget.month_year)
                        end
        redirect_to redirect_path, notice: "Expense added!", status: :see_other
      else
        @viewing_month = @budget.month_year
        @return_to = params[:return_to]
        render :new, status: :unprocessable_entity
      end
    end
  rescue => e
    # Handle any unexpected errors
    Rails.logger.error "Expense creation error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    month_year = params[:month] || Time.current.strftime("%Y-%m")
    @budget = current_user.monthly_budgets.find_by(month_year: month_year) || current_user.current_budget!
    @expense = @budget.expenses.new(expense_params)
    @expense.errors.add(:base, "An error occurred: #{e.message}")
    @viewing_month = @budget.month_year
    @return_to = params[:return_to]
    render :new, status: :unprocessable_entity
  end

  def edit
    @budget = @expense.monthly_budget
    @expense_templates = current_user.expense_templates.active.order(:name)
    @viewing_month = @budget.month_year
    @return_to = params[:return_to]
  end

  def update
    @budget = @expense.monthly_budget
    
    if @expense.update(expense_params)
      redirect_path = case params[:return_to]
                      when 'money_map'
                        money_map_path(scroll_to: 'spending-section')
                      else
                        expenses_path(month: @budget.month_year)
                      end
      redirect_to redirect_path, notice: "Expense updated!", status: :see_other
    else
      @expense_templates = current_user.expense_templates.active.order(:name)
      @viewing_month = @budget.month_year
      @return_to = params[:return_to]
      render :edit, status: :unprocessable_entity
    end
  end

  def start_next_month
    begin
      budget = current_user.create_next_month_budget!
      
      if budget
        next_month_name = Date.parse("#{budget.month_year}-01").strftime("%B %Y")
        expense_count = budget.expenses.count
        message = if expense_count > 0
          "#{next_month_name} ready! All your usual expenses (#{expense_count}) are here."
        else
          "#{next_month_name} ready! Create some expense templates to auto-add expenses next time."
        end
        redirect_to expenses_path(month: budget.month_year), notice: message
      else
        # Budget already exists - redirect to that month
        next_month = (Date.today + 1.month).strftime("%Y-%m")
        next_month_name = Date.parse("#{next_month}-01").strftime("%B %Y")
        redirect_to expenses_path(month: next_month), alert: "#{next_month_name}'s budget already exists!"
      end
    rescue => e
      Rails.logger.error "Error creating next month budget: #{e.message}"
      redirect_to expenses_path, alert: "Something went wrong. Please try again."
    end
  end

  def sweep_to_savings
    current_month = Time.current.strftime("%Y-%m")
    month_year = params[:month] || current_month
    
    # Only allow sweeping in current month
    if month_year != current_month
      redirect_to expenses_path(month: month_year), alert: "You can only sweep to savings in the current month."
      return
    end
    
    @budget = current_user.monthly_budgets.find_by(month_year: month_year)
    unless @budget
      redirect_to expenses_path, alert: "Budget not found."
      return
    end
    
    @expense = @budget.expenses.find_by(id: params[:expense_id])
    unless @expense
      redirect_to expenses_path(month: month_year), alert: "Expense not found."
      return
    end
    
    # Check if this is a savings expense
    unless @expense.name.downcase.include?("savings") || @expense.name.downcase.include?("emergency")
      redirect_to expenses_path(month: month_year), alert: "This expense is not a savings expense."
      return
    end
    
    flex_fund = @budget.unassigned
    if flex_fund <= 0
      redirect_to expenses_path(month: month_year), alert: "No flex fund available to sweep."
      return
    end
    
    amount = params[:amount].to_f
    if amount <= 0 || amount > flex_fund
      redirect_to expenses_path(month: month_year), alert: "Invalid amount. You can sweep up to #{helpers.number_to_currency(flex_fund)}."
      return
    end
    
    # Increase the expense's allotted_amount by the swept amount
    @expense.update(allotted_amount: @expense.allotted_amount + amount)
    
      redirect_to expenses_path(month: month_year), notice: "Great! You saved an extra #{helpers.number_to_currency(amount)} this month ✓"
  end

  def mark_paid
    current_month = Time.current.strftime("%Y-%m")
    
    # Only allow marking as paid in current month
    if @expense.monthly_budget.month_year != current_month
      redirect_to expenses_path(month: @expense.monthly_budget.month_year), alert: "You can only mark expenses as paid in the current month."
      return
    end
    
    # Check if already paid
    if @expense.paid?
      redirect_to expenses_path(month: current_month), notice: "This expense is already paid."
      return
    end
    
    # Calculate amount needed to mark as paid
    amount_needed = @expense.allotted_amount - @expense.spent_amount
    
    if amount_needed <= 0
      redirect_to expenses_path(month: current_month), alert: "This expense is already fully paid."
      return
    end
    
    # Create payment for the remaining amount
    payment = @expense.payments.create!(
      amount: amount_needed,
      spent_on: Date.today,
      notes: "Marked as paid"
    )
    
    redirect_to expenses_path(month: current_month), notice: "Payment added! #{helpers.number_to_currency(amount_needed)} paid to #{@expense.display_name}."
  end

  def destroy
    # Only allow deletion of one-off expenses (no template)
    unless @expense.expense_template_id.nil?
      redirect_to expenses_path(month: @expense.monthly_budget.month_year), 
                  alert: "Cannot delete expenses created from templates. Edit the template or set the amount to $0 instead."
      return
    end
    
    budget = @expense.monthly_budget
    month_year = budget.month_year
    @expense.destroy
    redirect_to expenses_path(month: month_year), 
                notice: "Expense deleted."
  end

  def add_payment
    @budget = @expense.monthly_budget
    current_month = Time.current.strftime("%Y-%m")
    
    # Only allow payments for current month
    if @budget.month_year != current_month
      redirect_path = case params[:return_to]
                      when 'money_map'
                        money_map_path(scroll_to: 'spending-section')
                      else
                        edit_expense_path(@expense, return_to: params[:return_to])
                      end
      redirect_to redirect_path, 
                  alert: "Payments can only be added to the current month.",
                  status: :see_other
      return
    end
    
    amount = params[:amount].to_f
    spent_on = params[:spent_on].present? ? Date.parse(params[:spent_on]) : Date.today
    notes = params[:notes]
    
    if amount <= 0
      redirect_path = case params[:return_to]
                      when 'money_map'
                        money_map_path(scroll_to: 'spending-section')
                      else
                        edit_expense_path(@expense, return_to: params[:return_to])
                      end
      redirect_to redirect_path, 
                  alert: "Payment amount must be greater than 0.",
                  status: :see_other
      return
    end
    
    payment = @expense.payments.build(
      amount: amount,
      spent_on: spent_on,
      notes: notes
    )
    
    if payment.save
      redirect_path = case params[:return_to]
                      when 'money_map'
                        money_map_path(scroll_to: 'spending-section')
                      else
                        edit_expense_path(@expense, return_to: params[:return_to])
                      end
      redirect_to redirect_path, 
                  notice: "Payment of #{helpers.number_to_currency(amount)} added!",
                  status: :see_other
    else
      redirect_path = case params[:return_to]
                      when 'money_map'
                        money_map_path(scroll_to: 'spending-section')
                      else
                        edit_expense_path(@expense, return_to: params[:return_to])
                      end
      redirect_to redirect_path, 
                  alert: "Error adding payment: #{payment.errors.full_messages.join(', ')}",
                  status: :see_other
    end
  end

  private

  def set_expense
    @expense = current_user.monthly_budgets.joins(:expenses).where(expenses: { id: params[:id] }).first&.expenses&.find_by(id: params[:id])
    unless @expense
      redirect_to expenses_path, alert: "Expense not found."
    end
  end

  def expense_params
    params.require(:expense).permit(:expense_template_id, :allotted_amount, :name)
  end
end

