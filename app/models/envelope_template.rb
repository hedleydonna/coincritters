# app/models/envelope_template.rb
class EnvelopeTemplate < ApplicationRecord
  belongs_to :user
  has_many :envelopes, dependent: :destroy

  # ------------------------------------------------------------------
  # Enums & Validations
  # ------------------------------------------------------------------
  enum :group_type, { fixed: 0, variable: 1 }, default: :variable

  validates :name, presence: true, uniqueness: { scope: :user_id, conditions: -> { where(is_active: true) } }
  validates :default_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Default ordering by name for consistent display
  default_scope -> { order(:name) }

  # ------------------------------------------------------------------
  # Scopes
  # ------------------------------------------------------------------
  # Active templates (default for most queries)
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  
  scope :fixed, -> { where(group_type: :fixed) }
  scope :variable, -> { where(group_type: :variable) }
  scope :savings, -> { where(is_savings: true) }
  scope :non_savings, -> { where(is_savings: false) }
  scope :auto_create, -> { where(auto_create: true) }

  # ------------------------------------------------------------------
  # Instance methods
  # ------------------------------------------------------------------
  
  # Friendly display name
  def display_name
    if is_savings?
      "#{name} (Savings)"
    else
      name
    end
  end

  def group_type_fixed?
    group_type == "fixed"
  end

  # Text description of group type
  def group_type_text
    group_type == "fixed" ? "Fixed bill" : "Variable spending"
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

