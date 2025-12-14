# app/models/payment.rb
class Payment < ApplicationRecord
  belongs_to :expense
  has_one :monthly_budget, through: :expense
  has_one :user, through: :monthly_budget

  # ------------------------------------------------------------------
  # Validations
  # ------------------------------------------------------------------
  validates :amount, presence: true, numericality: { greater_than: 0, message: "must be greater than 0" }
  validates :spent_on, presence: true

  # ------------------------------------------------------------------
  # Scopes
  # ------------------------------------------------------------------
  scope :recent, -> { order(spent_on: :desc, created_at: :desc) }
  scope :for_date, ->(date) { where(spent_on: date) }
  scope :for_date_range, ->(start_date, end_date) { where(spent_on: start_date..end_date) }
  scope :for_expense, ->(expense) { where(expense: expense) }

  # ------------------------------------------------------------------
  # Instance methods
  # ------------------------------------------------------------------
  
  # Get spending_group_name from the associated expense's spending_category
  def spending_group_name
    expense.name
  end
  
  # Formatted display of the payment amount using Rails currency helper
  def formatted_amount
    ActionController::Base.helpers.number_to_currency(amount, precision: 2)
  end

  # Check if this payment happened today
  def today?
    spent_on == Date.current
  end

  # Check if this payment happened this week
  def this_week?
    spent_on >= Date.current.beginning_of_week && spent_on <= Date.current.end_of_week
  end

  # Check if this payment happened this month
  def this_month?
    spent_on.year == Date.current.year && spent_on.month == Date.current.month
  end

  # Friendly string for debugging and display
  def to_s
    "#{formatted_amount} on #{spent_on.to_fs(:long)} – #{spending_group_name}"
  end
end

