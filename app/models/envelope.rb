# app/models/envelope.rb
class Envelope < ApplicationRecord
  belongs_to :monthly_budget
  belongs_to :spending_category
  has_one :user, through: :monthly_budget

  has_many :spendings, dependent: :destroy

  # ------------------------------------------------------------------
  # Validations
  # ------------------------------------------------------------------
  validates :allotted_amount,
            numericality: { greater_than_or_equal_to: 0 }

  # Ensure only one envelope per category per month
  validates :spending_category_id,
            uniqueness: { scope: :monthly_budget_id }

  # ------------------------------------------------------------------
  # Scopes
  # ------------------------------------------------------------------
  # Group type and savings scopes now come from spending_category
  scope :fixed, -> { joins(:spending_category).merge(SpendingCategory.fixed) }
  scope :variable, -> { joins(:spending_category).merge(SpendingCategory.variable) }
  scope :savings, -> { joins(:spending_category).merge(SpendingCategory.savings) }
  scope :non_savings, -> { joins(:spending_category).merge(SpendingCategory.non_savings) }
  
  # Quick scope for envelopes that are over budget
  scope :over_budget, -> { where("(SELECT COALESCE(SUM(s.amount), 0) FROM spendings s WHERE s.envelope_id = envelopes.id) > allotted_amount") }

  # ------------------------------------------------------------------
  # Auto-fill allotted_amount from category default when creating
  # ------------------------------------------------------------------
  before_validation :set_default_allotted_amount, on: :create, if: -> { spending_category_id.present? }

  # ------------------------------------------------------------------
  # Calculated values — live from spends
  # ------------------------------------------------------------------
  def spent_amount
    spendings.sum(:amount)
  end

  def remaining
    allotted_amount - spent_amount
  end

  def percent_used
    allotted_amount.zero? ? 0 : ((spent_amount / allotted_amount) * 100).round
  end

  # Fixed bills are "paid" when spent >= allotted
  def paid?
    spending_category.group_type_fixed? && spent_amount >= allotted_amount
  end

  def over_budget?
    spent_amount > allotted_amount
  end

  def under_budget?
    spent_amount < allotted_amount
  end

  # How much is available (never negative)
  def available
    [remaining, 0].max
  end

  # Percentage of allotted amount spent (capped at 100%)
  def spent_percentage
    allotted_amount.positive? ? [(spent_amount / allotted_amount * 100).round(1), 100].min : 0
  end

  # ------------------------------------------------------------------
  # Delegated methods from spending_category
  # ------------------------------------------------------------------
  def group_type
    spending_category.group_type
  end

  def fixed?
    spending_category.fixed?
  end

  def variable?
    spending_category.variable?
  end

  def savings?
    spending_category.is_savings?
  end

  # Alias for backward compatibility
  def is_savings?
    savings?
  end

  def name
    spending_category.name
  end

  def display_name
    spending_category.display_name
  end

  def group_type_text
    spending_category.group_type_text
  end

  # Alias for backward compatibility
  def spending_group_name
    name
  end

  # ------------------------------------------------------------------
  # Display helpers
  # ------------------------------------------------------------------
  # Helper for variable spending forms
  def display_name_with_budget
    "#{name} (#{monthly_budget.month_year})"
  end

  # Friendly string for debugging / selects
  def to_s
    "#{name} (#{monthly_budget.name})"
  end

  private

  def set_default_allotted_amount
    # Reload spending_category to ensure default_amount is available
    category = spending_category || SpendingCategory.find_by(id: spending_category_id)
    return unless category
    
    # Only set if allotted_amount is nil or zero (not explicitly set)
    # Use category's default_amount, which defaults to 0.0 if not set
    if allotted_amount.nil? || allotted_amount.zero?
      self.allotted_amount = category.default_amount || 0
    end
  end
end

