# app/models/monthly_budget.rb
class MonthlyBudget < ApplicationRecord
    belongs_to :user
    has_many :envelopes, dependent: :destroy
  
    # ------------------------------------------------------------------
    # Validations
    # ------------------------------------------------------------------
    validates :month_year, 
              presence: true,
              format: { with: /\A\d{4}-\d{2}\z/, message: "must be YYYY-MM" },
              uniqueness: { scope: :user_id }
  
    validates :total_actual_income, 
              numericality: { greater_than_or_equal_to: 0 }
  
    validates :flex_fund, 
              numericality: { greater_than_or_equal_to: 0 }
  
    # ------------------------------------------------------------------
    # Scopes — super handy
    # ------------------------------------------------------------------
    scope :current, -> { find_by(month_year: Time.current.strftime("%Y-%m")) }
    scope :for_month, ->(year_month) { find_by(month_year: year_month) }
  
    # ------------------------------------------------------------------
    # Instance methods
    # ------------------------------------------------------------------
    def name
      Date.parse("#{month_year}-01").strftime("%B %Y")
    end
  
    # Total allotted to envelopes
    def total_allotted
      envelopes.sum(:allotted_amount)
    end
  
    # Total spent across all envelopes
    def total_spent
      envelopes.sum(:spent_amount)
    end
  
    # Remaining after envelopes — this is what shows on the dashboard
    def remaining
      total_actual_income - total_allotted
    end
  
    # How much is "unassigned" (can be swept to savings or next month)
    def unassigned
      [remaining, 0].max
    end
  
    # Optional: forgiving bank balance check
    def bank_difference
      return nil unless bank_balance.present?
      bank_balance - (total_actual_income - total_spent)
    end
  
    def bank_match?
      return true unless bank_balance.present?
      bank_difference.abs <= 50 # "close enough" — adjust as you like
    end
  end
  