# app/models/monthly_budget.rb
class MonthlyBudget < ApplicationRecord
  belongs_to :user
  has_many :expenses, dependent: :destroy

  # ------------------------------------------------------------------
  # Validations
  # ------------------------------------------------------------------
  validates :month_year, 
            presence: true,
            uniqueness: { scope: :user_id },
            format: { with: /\A\d{4}-\d{2}\z/, message: "must be YYYY-MM" }

  validates :total_actual_income, 
            numericality: { greater_than_or_equal_to: 0 }

  validates :flex_fund, 
            numericality: { greater_than_or_equal_to: 0 }

  validates :bank_balance, 
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # ------------------------------------------------------------------
  # Scopes
  # ------------------------------------------------------------------
  scope :current, -> { find_by(month_year: Time.current.strftime("%Y-%m")) }
  scope :for_month, ->(year_month) { find_by(month_year: year_month) }
  scope :by_month, ->(month_year) { where(month_year: month_year) }
  scope :for_user, ->(user) { where(user: user) }

  # ------------------------------------------------------------------
  # Friendly name
  # ------------------------------------------------------------------
  def name
    Date.parse("#{month_year}-01").strftime("%B %Y")
  end

  # Helper for dropdown display in admin forms
  def month_year_with_user
    "#{month_year} - #{user.display_name.presence || user.email.split('@').first.capitalize}"
  end

  # ------------------------------------------------------------------
  # Calculated totals — no stored columns needed
  # ------------------------------------------------------------------
  def total_allotted
    expenses.sum(:allotted_amount)
  end

  def total_spent
    expenses.sum(&:spent_amount)
  end

  def remaining_to_assign
    total_actual_income - total_allotted
  end

  def unassigned
    [remaining_to_assign, 0].max
  end

  # ------------------------------------------------------------------
  # Forgiving bank balance check
  # ------------------------------------------------------------------
  def bank_difference
    return nil unless bank_balance.present?

    bank_balance - (total_actual_income - total_spent)
  end

  def bank_match?
    return true unless bank_balance.present?

    bank_difference.abs <= 50  # "close enough" — adjust if you want
  end

  # ------------------------------------------------------------------
  # Auto-create expenses from user's recurring templates
  # ------------------------------------------------------------------
  def auto_create_expenses
    user.expense_templates.active.auto_create.find_each do |template|
      # Skip if expense for this template already exists in this budget
      next if expenses.exists?(expense_template_id: template.id)

      expenses.create!(
        expense_template: template,
        allotted_amount: template.default_amount || 0
      )
    end
  end

  # Alias for backward compatibility
  alias_method :auto_create_envelopes, :auto_create_expenses
end