# app/models/envelope.rb
class Envelope < ApplicationRecord
  belongs_to :monthly_budget
  belongs_to :spending_category
  has_one :user, through: :monthly_budget

  has_many :variable_spending, dependent: :destroy
  has_many :bill_payments, dependent: :destroy

  # ------------------------------------------------------------------
  # Validations
  # ------------------------------------------------------------------
  validates :allotted_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :spent_amount, numericality: { greater_than_or_equal_to: 0 }

  validates :spending_group_name, 
  presence: true,
  uniqueness: { scope: :monthly_budget_id, message: "already exists for this budget" }

  # ------------------------------------------------------------------
  # Scopes
  # ------------------------------------------------------------------
  # Group type and savings scopes now come from spending_category
  scope :fixed, -> { joins(:spending_category).merge(SpendingCategory.fixed) }
  scope :variable, -> { joins(:spending_category).merge(SpendingCategory.variable) }
  scope :savings, -> { joins(:spending_category).merge(SpendingCategory.savings) }
  scope :non_savings, -> { joins(:spending_category).merge(SpendingCategory.non_savings) }

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

  # Get group_type from spending_category
  def group_type
    spending_category.group_type
  end

  # Boolean methods for group_type (delegated to spending_category)
  def fixed?
    spending_category.fixed?
  end

  def variable?
    spending_category.variable?
  end

  # Get is_savings from spending_category
  def is_savings?
    spending_category.is_savings?
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

  # For forms — show nice text (delegates to spending_category)
  def group_type_text
    spending_category.group_type_text
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
