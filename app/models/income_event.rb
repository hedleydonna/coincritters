class IncomeEvent < ApplicationRecord
  belongs_to :user
  belongs_to :income_template, optional: true

  validates :month_year, presence: true
  validates :received_on, presence: true
  validates :actual_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :actual_amount, numericality: { greater_than: 0 }, presence: true, if: -> { income_template_id.nil? }
  validates :custom_label, presence: true, if: -> { income_template_id.nil? }
  
  # Validate month_year format (YYYY-MM)
  validates :month_year, format: { with: /\A\d{4}-\d{2}\z/, message: "must be in YYYY-MM format" }

  # Auto-update monthly budget's total_actual_income when income events change
  after_save :update_monthly_budget_income
  after_destroy :update_monthly_budget_income

  # Display name logic: use income_template.name if linked, otherwise custom_label
  def display_name
    income_template&.name || custom_label
  end

  # Helper to get the month this income counts toward
  def assigned_month
    apply_to_next_month ? (Date.parse("#{month_year}-01") + 1.month).strftime("%Y-%m") : month_year
  end

  private

  def update_monthly_budget_income
    # Determine which month this income should count toward
    target_month = if apply_to_next_month
      # If deferred, calculate next month from month_year
      month_date = Date.parse("#{month_year}-01")
      (month_date + 1.month).strftime("%Y-%m")
    else
      # Otherwise, count in the month received
      month_year
    end
    
    return unless target_month.present?

    # Find or create the budget for this month
    budget = user.monthly_budgets.find_or_create_by(month_year: target_month) do |b|
      # Budget will be created with default values (total_actual_income: 0.0)
    end

    # Recalculate total_actual_income from all income events assigned to this month
    # Count events where: (month_year matches AND apply_to_next_month is false) OR (month_year is previous month AND apply_to_next_month is true)
    current_month_events = user.income_events.where(month_year: target_month, apply_to_next_month: false)
    
    # Also count events from previous month that are deferred to this month
    prev_month = (Date.parse("#{target_month}-01") - 1.month).strftime("%Y-%m")
    deferred_events = user.income_events.where(month_year: prev_month, apply_to_next_month: true)
    
    total = (current_month_events.sum(:actual_amount) + deferred_events.sum(:actual_amount))
    
    budget.update_column(:total_actual_income, total)
  end
end
