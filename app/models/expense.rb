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
  validates :allotted_amount,
            numericality: { greater_than: 0 },
            presence: true,
            if: -> { expense_template_id.nil? }

  # Name is always required (copied from template when created, or entered for one-offs)
  # Note: The name method returns "Unnamed Expense" when attribute is nil, but validation checks the attribute
  # We need to validate the attribute directly, not the method
  validate :name_attribute_must_be_present
  
  def name_attribute_must_be_present
    if read_attribute(:name).blank?
      errors.add(:name, "can't be blank")
    end
  end

  # Allow multiple expenses per template per month (needed for weekly/bi-weekly expenses)
  # Previously we only allowed one expense per template, but now we need multiple for recurring expenses
  # with frequencies like weekly or bi-weekly

  # Allow multiple expenses with the same name (removed uniqueness constraint)

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
  # Name - stored directly on expense (copied from template when created)
  # ------------------------------------------------------------------
  def name
    read_attribute(:name).presence || "Unnamed Expense"
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
    # Use expected_on if set (for weekly/bi-weekly expenses), otherwise use template's due_date
    read_attribute(:expected_on) || expense_template&.due_date
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

