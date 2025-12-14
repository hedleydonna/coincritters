# app/models/expense.rb
class Expense < ApplicationRecord
  belongs_to :monthly_budget
  belongs_to :expense_template, optional: true
  has_one :user, through: :monthly_budget

  has_many :payments, dependent: :destroy

  # ------------------------------------------------------------------
  # Validations
  # ------------------------------------------------------------------
  validates :allotted_amount,
            numericality: { greater_than_or_equal_to: 0 }

  # Require name when no template is provided (one-off expenses)
  validates :name,
            presence: true,
            if: -> { expense_template_id.nil? }

  # Require template when name is not provided (unless it's a one-off)
  validates :expense_template_id,
            presence: true,
            unless: -> { read_attribute(:name).present? }

  # Ensure only one expense per template per month (unless using name override or one-off)
  # If name is overridden or it's a one-off, we allow multiple expenses
  validates :expense_template_id,
            uniqueness: { scope: :monthly_budget_id, 
                         message: "already has an expense for this template in this budget",
                         allow_nil: true },
            unless: -> { read_attribute(:name).present? || expense_template_id.nil? }

  # If using name (either override or one-off), ensure unique name per budget
  validates :name,
            uniqueness: { scope: :monthly_budget_id, allow_nil: true },
            if: -> { read_attribute(:name).present? }

  # ------------------------------------------------------------------
  # Scopes
  # ------------------------------------------------------------------
  # Quick scope for expenses that are over budget
  scope :over_budget, -> { where("(SELECT COALESCE(SUM(p.amount), 0) FROM payments p WHERE p.expense_id = expenses.id) > allotted_amount") }
  
  # Scope for expenses by frequency (only applies to expenses with templates)
  scope :by_frequency, ->(freq) {
    joins(:expense_template).merge(ExpenseTemplate.by_frequency(freq))
  }

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

  # Check if expense is "paid" (spent >= allotted)
  def paid?
    spent_amount >= allotted_amount
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
    name
  end

  # ------------------------------------------------------------------
  # Template-delegated methods
  # ------------------------------------------------------------------
  def frequency
    expense_template&.frequency || "monthly"
  end

  def due_date
    expense_template&.due_date
  end

  def frequency_text
    expense_template&.frequency_text || "Monthly"
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

