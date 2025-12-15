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

  def remaining_to_assign
    total_actual_income - total_allotted
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
      
      # Determine if this is the last payment of the month (for deferral logic)
      last_event_date = event_dates.last
      
      event_dates.each do |event_date|
        # Skip if income event for this income_template and date already exists
        next if user.income_events.exists?(
          income_template_id: income.id,
          received_on: event_date,
          month_year: event_date.strftime("%Y-%m")
        )
        
        # Determine if this event should be deferred to next month
        # Only defer if: it's the last payment of the month AND template has last_payment_to_next_month enabled
        apply_to_next = income.last_payment_to_next_month? && event_date == last_event_date
        
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
          apply_to_next_month: apply_to_next,
          actual_amount: actual_amount
        )
      end
    end
  end

  # ------------------------------------------------------------------
  # Calculate expected income for this month
  # Note: This includes income that might be deferred from previous month
  # ------------------------------------------------------------------
  def expected_income
    # Income from events assigned to this month (not deferred)
    current_month_expected = user.income_templates.active.auto_create.sum do |income_template|
      income_template.expected_amount_for_month(month_year)
    end
    
    # Also include income deferred from previous month
    prev_month = (Date.parse("#{month_year}-01") - 1.month).strftime("%Y-%m")
    deferred_expected = user.income_templates.active.auto_create.select do |income_template|
      income_template.last_payment_to_next_month?
    end.sum do |income_template|
      # Get last payment amount from previous month
      prev_month_events = income_template.events_for_month(prev_month)
      prev_month_events.any? ? income_template.estimated_amount : 0
    end
    
    current_month_expected + deferred_expected
  end
end
