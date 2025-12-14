# app/models/expense_template.rb
class ExpenseTemplate < ApplicationRecord
  belongs_to :user
  has_many :expenses, dependent: :destroy

  # ------------------------------------------------------------------
  # Validations
  # ------------------------------------------------------------------
  validates :name, presence: true, uniqueness: { scope: :user_id, conditions: -> { where(is_active: true) } }
  validates :default_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :frequency, inclusion: { in: %w[monthly weekly biweekly yearly], message: "%{value} is not a valid frequency" }, allow_nil: true

  # Default ordering by name for consistent display
  default_scope -> { order(:name) }

  # ------------------------------------------------------------------
  # Scopes
  # ------------------------------------------------------------------
  # Active templates (default for most queries)
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :auto_create, -> { where(auto_create: true) }
  scope :by_frequency, ->(freq) { where(frequency: freq) }

  # ------------------------------------------------------------------
  # Instance methods
  # ------------------------------------------------------------------
  
  # Friendly display name
  def display_name
    name
  end

  # Frequency display helper
  def frequency_text
    case frequency
    when "monthly"
      "Monthly"
    when "weekly"
      "Weekly"
    when "biweekly"
      "Biweekly"
    when "yearly"
      "Yearly"
    else
      "Monthly" # default
    end
  end

  # Soft delete: deactivate the template instead of destroying it
  def deactivate!
    update(is_active: false)
  end

  # Reactivate a deactivated template
  def activate!
    update(is_active: true)
  end

  # Check if template is active
  def active?
    is_active?
  end
end

