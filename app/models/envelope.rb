# app/models/envelope.rb
class Envelope < ApplicationRecord
  belongs_to :monthly_budget
  has_one :user, through: :monthly_budget

  has_many :variable_spending, dependent: :destroy
  # TODO: Uncomment when bill_payments model is created
  # has_many :bill_payments, dependent: :destroy

  # ------------------------------------------------------------------
  # Enums & Validations
  # ------------------------------------------------------------------
  enum :group_type, { fixed: 0, variable: 1 }, default: :variable

  validates :allotted_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :spent_amount, numericality: { greater_than_or_equal_to: 0 }

  validates :spending_group_name, 
  presence: true,
  uniqueness: { scope: :monthly_budget_id, message: "already exists for this budget" }

  # ------------------------------------------------------------------
  # Scopes
  # ------------------------------------------------------------------
  scope :savings, -> { where(is_savings: true) }
  scope :non_savings, -> { where(is_savings: false) }
  
  # Rails enum automatically provides these scopes, but we can keep them explicit if needed
  # The enum :group_type automatically creates .fixed and .variable scopes

  # ------------------------------------------------------------------
  # Instance methods
  # ------------------------------------------------------------------
  def remaining
    allotted_amount - spent_amount
  end

  def percent_used
    return 0 if allotted_amount.zero?
    (spent_amount / allotted_amount * 100).round
  end

  def over_budget?
    spent_amount > allotted_amount
  end

  def under_budget?
    spent_amount < allotted_amount
  end

  # Friendly display name
  def display_name
    if is_savings?
      "#{spending_group_name} (Savings)"
    else
      spending_group_name
    end
  end

  # How much is available (never negative)
  def available
    [remaining, 0].max
  end

  # For forms — show nice text
  def group_type_text
    group_type == "fixed" ? "Fixed bill" : "Variable spending"
  end

  # Percentage of allotted amount spent
  def spent_percentage
    return 0 if allotted_amount.zero?
    [(spent_amount / allotted_amount * 100).round(1), 100].min
  end

  # Helper for variable spending forms
  def display_name_with_budget
    "#{spending_group_name} (#{monthly_budget.month_year})"
  end
end
