class IncomeEvent < ApplicationRecord
  belongs_to :user
  belongs_to :income, optional: true

  validates :month_year, presence: true
  validates :received_on, presence: true
  validates :actual_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :custom_label, presence: true, if: -> { income_id.nil? }
  
  # Validate month_year format (YYYY-MM)
  validates :month_year, format: { with: /\A\d{4}-\d{2}\z/, message: "must be in YYYY-MM format" }
  validates :assigned_month_year, format: { with: /\A\d{4}-\d{2}\z/, message: "must be in YYYY-MM format" }, allow_blank: true

  # Display name logic: use income.name if linked, otherwise custom_label
  def display_name
    income&.name || custom_label
  end
end
