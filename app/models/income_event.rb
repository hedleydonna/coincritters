class IncomeEvent < ApplicationRecord
  belongs_to :user
  belongs_to :income, optional: true

  validates :month_year, presence: true
  validates :received_on, presence: true
  validates :actual_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :income_type, presence: true
  
  # Validate month_year format (YYYY-MM)
  validates :month_year, format: { with: /\A\d{4}-\d{2}\z/, message: "must be in YYYY-MM format" }
  validates :assigned_month_year, format: { with: /\A\d{4}-\d{2}\z/, message: "must be in YYYY-MM format" }, allow_blank: true
end
