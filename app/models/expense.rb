# app/models/expense.rb
class Expense < ApplicationRecord
  belongs_to :monthly_budget
  belongs_to :expense_template
  has_one :user, through: :monthly_budget

  has_many :payments, dependent: :destroy

  # ------------------------------------------------------------------
  # Validations
  # ------------------------------------------------------------------
  validates :allotted_amount,
            numericality: { greater_than_or_equal_to: 0 }

  # Ensure only one expense per template per month (unless using name override)
  # If name is overridden, we allow multiple expenses from same template
  validates :expense_template_id,
            uniqueness: { scope: :monthly_budget_id, 
                         message: "already has an expense for this template in this budget" },
            unless: -> { read_attribute(:name).present? } # Allow duplicates if using name override

  # If using name override, ensure unique name per budget
  validates :name,
            uniqueness: { scope: :monthly_budget_id, allow_nil: true },
            if: -> { read_attribute(:name).present? }

  # ------------------------------------------------------------------
  # Scopes
  # ------------------------------------------------------------------
  # Scopes that delegate to template (group_type and is_savings always come from template)
  scope :fixed, -> {
    joins(:expense_template).merge(ExpenseTemplate.fixed)
  }
  
  scope :variable, -> {
    joins(:expense_template).merge(ExpenseTemplate.variable)
  }
  
  scope :savings, -> {
    joins(:expense_template).merge(ExpenseTemplate.savings)
  }
  
  scope :non_savings, -> {
    joins(:expense_template).merge(ExpenseTemplate.non_savings)
  }
  
  # Quick scope for expenses that are over budget
  scope :over_budget, -> { where("(SELECT COALESCE(SUM(p.amount), 0) FROM payments p WHERE p.expense_id = expenses.id) > allotted_amount") }

  # ------------------------------------------------------------------
  # Auto-fill allotted_amount from template default when creating
  # ------------------------------------------------------------------
  before_validation :set_default_allotted_amount, on: :create, if: -> { expense_template_id.present? }

  # ------------------------------------------------------------------
  # Calculated values — live from payments
  # ------------------------------------------------------------------
  def spent_amount
    payments.sum(:amount)
  end

  def remaining
    allotted_amount - spent_amount
  end

  def percent_used
    allotted_amount.zero? ? 0 : ((spent_amount / allotted_amount) * 100).round
  end

  # Fixed bills are "paid" when spent >= allotted
  def paid?
    fixed? && spent_amount >= allotted_amount
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
  # Name override - use override if present, fallback to template
  # ------------------------------------------------------------------
  def name
    read_attribute(:name).presence || expense_template&.name || "Unnamed Expense"
  end

  def display_name
    if is_savings?
      "#{name} (Savings)"
    else
      name
    end
  end

  # ------------------------------------------------------------------
  # Template-delegated methods - always come from template
  # ------------------------------------------------------------------
  def group_type
    expense_template&.group_type || "variable"
  end

  def fixed?
    expense_template&.fixed? || false
  end

  def variable?
    return expense_template.variable? if expense_template
    false  # Default to false if no template (shouldn't happen in practice)
  end

  def savings?
    expense_template&.is_savings? || false
  end

  # Alias for backward compatibility
  def is_savings?
    savings?
  end

  def group_type_fixed?
    fixed?
  end

  def group_type_text
    fixed? ? "Fixed bill" : "Variable payment"
  end

  # Alias for backward compatibility
  def spending_group_name
    name
  end

  # Check if expense has name override
  def has_overrides?
    read_attribute(:name).present?
  end

  def name_overridden?
    read_attribute(:name).present?
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
    # Reload expense_template to ensure default_amount is available
    template = expense_template || ExpenseTemplate.find_by(id: expense_template_id)
    return unless template
    
    # Only set if allotted_amount is nil or zero (not explicitly set)
    # Use template's default_amount, which defaults to 0.0 if not set
    if allotted_amount.nil? || allotted_amount.zero?
      self.allotted_amount = template.default_amount || 0
    end
  end
end

