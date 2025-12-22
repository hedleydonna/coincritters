# app/controllers/income_templates_controller.rb
class IncomeTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_income_template, only: %i[edit update destroy toggle_auto_create]
  before_action :set_deleted_income_template, only: [:reactivate]

  def index
    # Get all active templates (not deleted) - disabled means auto_create: false
    @income_templates = current_user.income_templates.active.order(:name)
    
    @return_to = params[:return_to] # 'income_events', 'money_map', 'settings', or nil
  end

  def new
    @income_template = current_user.income_templates.new
    @income_template.frequency = "monthly"
    @income_template.auto_create = true  # Default to true
    @return_to = params[:return_to]
  end

  def create
    @income_template = current_user.income_templates.new(income_template_params)
    @income_template.auto_create = true  # Default to true when creating
    if @income_template.save
      # Always return to income_templates index page after creating
      # The return_to parameter is preserved for navigation context
      redirect_to income_templates_path(return_to: params[:return_to]), status: :see_other, notice: "Money in source created!"
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
      redirect_path = case params[:return_to]
                      when 'income_events'
                        income_events_path
                      when 'money_map'
                        money_map_path(scroll_to: 'money-in-section')
                      else
                        income_templates_path(return_to: params[:return_to])
                      end
      redirect_to redirect_path, status: :see_other, notice: "Income source updated!"
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
    redirect_path = case params[:return_to]
                    when 'money_map'
                      money_map_path(scroll_to: 'money-in-section')
                    when 'income_events'
                      income_events_path
                    else
                      income_templates_path(return_to: params[:return_to])
                    end
    redirect_to redirect_path, status: :see_other, notice: "Money in source restored!"
  end

  def toggle_auto_create
    was_enabled = @income_template.auto_create?
    @income_template.update(auto_create: !was_enabled)
    
    # If disabling auto-create, delete next month events (only if actual_amount == 0)
    if was_enabled && !@income_template.auto_create?
      # Disabling - delete next month preview events (only if no actual_amount entered)
      next_month_str = (Date.today + 1.month).strftime("%Y-%m")
      next_month_events = current_user.income_events
        .where(income_template_id: @income_template.id, month_year: next_month_str)
        .where("actual_amount = 0 OR actual_amount IS NULL")
      
      deleted_count = next_month_events.count
      next_month_events.destroy_all
      
      notice = if deleted_count > 0
        "Auto-create disabled. #{deleted_count} preview event#{'s' if deleted_count > 1} for next month removed."
      else
        "Auto-create disabled. Future events will not be automatically created."
      end
    else
      # Enabling - no action needed, events will be created when viewing that month
      notice = "Auto-create enabled. Events will be automatically created each month."
    end
    
    redirect_path = if params[:return_to] == 'income_events'
      income_events_path
    else
      income_templates_path(return_to: params[:return_to])
    end
    redirect_to redirect_path, notice: notice
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
      :active
      # Removed :auto_create - handled separately via toggle_auto_create action
      # Removed :last_payment_to_next_month - deferral functionality removed
    )
  end
end

