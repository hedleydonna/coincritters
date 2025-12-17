# app/models/expense_template.rb
class ExpenseTemplate < ApplicationRecord
  belongs_to :user
  has_many :expenses, dependent: :destroy

  # ------------------------------------------------------------------
  # Validations
  # ------------------------------------------------------------------
  validates :name, presence: true, uniqueness: { scope: :user_id, conditions: -> { where(deleted_at: nil) } }
  validates :default_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :frequency, inclusion: { in: %w[monthly weekly biweekly yearly], message: "%{value} is not a valid frequency" }, allow_nil: true

  # Default scope excludes deleted items and orders by name
  default_scope -> { where(deleted_at: nil).order(:name) }

  # ------------------------------------------------------------------
  # Scopes
  # ------------------------------------------------------------------
  # Active templates (not deleted)
  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { unscope(where: :deleted_at).where.not(deleted_at: nil) }
  scope :with_deleted, -> { unscope(where: :deleted_at) }
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

  # Soft delete: set deleted_at timestamp
  def soft_delete!
    update(deleted_at: Time.current)
  end

  # Restore a deleted template
  def restore!
    update(deleted_at: nil)
  end

  # Check if template is deleted
  def deleted?
    deleted_at.present?
  end

  # Alias for compatibility
  def active?
    deleted_at.nil?
  end
end

