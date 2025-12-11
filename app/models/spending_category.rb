# app/models/spending_category.rb
class SpendingCategory < ApplicationRecord
  belongs_to :user
  has_many :envelopes, dependent: :destroy

  # ------------------------------------------------------------------
  # Enums & Validations
  # ------------------------------------------------------------------
  enum :group_type, { fixed: 0, variable: 1 }, default: :variable

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :default_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # ------------------------------------------------------------------
  # Scopes
  # ------------------------------------------------------------------
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
end

