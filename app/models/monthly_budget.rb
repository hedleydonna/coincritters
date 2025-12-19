# app/models/monthly_budget.rb
class MonthlyBudget < ApplicationRecord
  belongs_to :user
  has_many :expenses, dependent: :destroy

  # ------------------------------------------------------------------
  # Validations
  # ------------------------------------------------------------------
  validates :month_year, 
            presence: true,
            uniqueness: { scope: :user_id },
            format: { with: /\A\d{4}-\d{2}\z/, message: "must be YYYY-MM" }

  validates :total_actual_income, 
            numericality: { greater_than_or_equal_to: 0 }

  validates :flex_fund, 
            numericality: { greater_than_or_equal_to: 0 }

  validates :bank_balance, 
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # ------------------------------------------------------------------
  # Scopes
  # ------------------------------------------------------------------
  scope :current, -> { find_by(month_year: Time.current.strftime("%Y-%m")) }
  scope :for_month, ->(year_month) { find_by(month_year: year_month) }
  scope :by_month, ->(month_year) { where(month_year: month_year) }
  scope :for_user, ->(user) { where(user: user) }

  # ------------------------------------------------------------------
  # Friendly name
  # ------------------------------------------------------------------
  def name
    Date.parse("#{month_year}-01").strftime("%B %Y")
  end

  # Helper for dropdown display in admin forms
  def month_year_with_user
    "#{month_year} - #{user.display_name.presence || user.email.split('@').first.capitalize}"
  end

  # ------------------------------------------------------------------
  # Calculated totals — no stored columns needed
  # ------------------------------------------------------------------
  def total_allotted
    expenses.sum(:allotted_amount)
  end

  def total_spent
    expenses.sum(&:spent_amount)
  end

  # ------------------------------------------------------------------
  # Automatic carryover from previous month
  # ------------------------------------------------------------------
  def carryover_from_previous_month
    return 0.0 unless month_year.present?
    
    prev_month = (Date.parse("#{month_year}-01") - 1.month).strftime("%Y-%m")
    prev_budget = user.monthly_budgets.find_by(month_year: prev_month)
    return 0.0 unless prev_budget
    
    # Calculate previous month's balance: income - spent (can be positive or negative)
    prev_budget.total_actual_income - prev_budget.total_spent
  end

  def available_income
    total_actual_income + carryover_from_previous_month
  end

  def remaining_to_assign
    available_income - total_allotted
  end

  def unassigned
    [remaining_to_assign, 0].max
  end

  # ------------------------------------------------------------------
  # Forgiving bank balance check
  # ------------------------------------------------------------------
  def bank_difference
    return nil unless bank_balance.present?

    bank_balance - (total_actual_income - total_spent)
  end

  def bank_match?
    return true unless bank_balance.present?

    bank_difference.abs <= 50  # "close enough" — adjust if you want
  end

  # ------------------------------------------------------------------
  # Auto-create expenses from user's recurring templates
  # ------------------------------------------------------------------
  def auto_create_expenses
    user.expense_templates.active.auto_create.find_each do |template|
      # Skip if expense for this template already exists in this budget
      next if expenses.exists?(expense_template_id: template.id)

      expenses.create!(
        expense_template: template,
        allotted_amount: template.default_amount || 0
      )
    end
  end

  # Alias for backward compatibility
  alias_method :auto_create_envelopes, :auto_create_expenses

  # ------------------------------------------------------------------
  # Auto-create income events from user's recurring income templates
  # ------------------------------------------------------------------
  def auto_create_income_events
    user.income_templates.active.auto_create.find_each do |income|
      # Get all event dates for this month based on frequency and due_date
      event_dates = income.events_for_month(month_year)
      
      # For current month, only create events from today forward
      # For future months, create all events
      current_month_str = Time.current.strftime("%Y-%m")
      if month_year == current_month_str
        event_dates = event_dates.select { |date| date >= Date.today }
      end
      
      event_dates.each do |event_date|
        # Skip if income event for this income_template and date already exists
        next if user.income_events.exists?(
          income_template_id: income.id,
          received_on: event_date,
          month_year: event_date.strftime("%Y-%m")
        )
        
        # Create the income event with actual_amount set to 0 initially
        # User will update it when they confirm receipt, or it can be auto-filled on due date
        actual_amount = if event_date == Date.today
          # If it's the due date (today), pre-fill with estimated amount
          income.estimated_amount
        else
          # If due date is in the future or past, leave it at 0 until user acknowledges receipt
          0
        end
        
        user.income_events.create!(
          income_template: income,
          received_on: event_date,
          month_year: event_date.strftime("%Y-%m"),
          apply_to_next_month: false, # Defer functionality removed - use automatic carryover instead
          actual_amount: actual_amount
        )
      end
    end
  end

  # ------------------------------------------------------------------
  # Calculate expected income for this month
  # Logic:
  # 1. For template-based events: Count events per template × template.estimated_amount
  # 2. For one-off events: Sum their actual_amount values
  # Note: Defer functionality removed - use automatic carryover instead
  # ------------------------------------------------------------------
  def expected_income
    # Get all events for this month (no defer logic)
    current_month_events = user.income_events
      .where(month_year: month_year, apply_to_next_month: false)
      .includes(:income_template)
    
    # Group template-based events by template and calculate: count × estimated_amount
    template_events = current_month_events.select { |e| e.income_template_id.present? && e.income_template.present? }
    template_expected = template_events
      .group_by(&:income_template_id)
      .sum do |template_id, events|
        template = IncomeTemplate.find(template_id)
        events.count * template.estimated_amount
      end
    
    # Add one-off events (no template): sum their actual_amount
    one_off_events = current_month_events.select { |e| e.income_template_id.nil? }
    one_off_expected = one_off_events.sum { |e| e.actual_amount || 0 }
    
    template_expected + one_off_expected
  end
end
