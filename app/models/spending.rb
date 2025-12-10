# app/models/spending.rb
class Spending < ApplicationRecord
  belongs_to :envelope
  has_one :monthly_budget, through: :envelope
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
  scope :for_envelope, ->(envelope) { where(envelope: envelope) }

  # ------------------------------------------------------------------
  # Instance methods
  # ------------------------------------------------------------------
  
  # Get spending_group_name from the associated envelope's spending_category
  def spending_group_name
    envelope.name
  end
  
  # Formatted display of the spending amount
  def formatted_amount
    "$#{amount.to_f.round(2)}"
  end

  # Check if this spending happened today
  def today?
    spent_on == Date.today
  end

  # Check if this spending happened this week
  def this_week?
    spent_on >= Date.today.beginning_of_week && spent_on <= Date.today.end_of_week
  end

  # Check if this spending happened this month
  def this_month?
    spent_on >= Date.today.beginning_of_month && spent_on <= Date.today.end_of_month
  end
end

