class BillPayment < ApplicationRecord
  belongs_to :envelope
  has_one :monthly_budget, through: :envelope
  has_one :user, through: :monthly_budget

  # ------------------------------------------------------------------
  # Validations
  # ------------------------------------------------------------------
  validates :actual_paid_amount, presence: true, numericality: { greater_than: 0, message: "must be greater than 0" }
  validates :paid_on, presence: true

  # ------------------------------------------------------------------
  # Scopes
  # ------------------------------------------------------------------
  scope :recent, -> { order(paid_on: :desc, created_at: :desc) }
  scope :for_date, ->(date) { where(paid_on: date) }
  scope :for_date_range, ->(start_date, end_date) { where(paid_on: start_date..end_date) }
  scope :for_envelope, ->(envelope) { where(envelope: envelope) }

  # ------------------------------------------------------------------
  # Instance methods
  # ------------------------------------------------------------------
  
  # Get spending_group_name from the associated envelope
  def spending_group_name
    envelope.spending_group_name
  end
  
  # Formatted display of the payment amount
  def formatted_amount
    "$#{actual_paid_amount.to_f.round(2)}"
  end

  # Check if this payment was made today
  def today?
    paid_on == Date.today
  end

  # Check if this payment was made this week
  def this_week?
    paid_on >= Date.today.beginning_of_week && paid_on <= Date.today.end_of_week
  end

  # Check if this payment was made this month
  def this_month?
    paid_on >= Date.today.beginning_of_month && paid_on <= Date.today.end_of_month
  end
end

