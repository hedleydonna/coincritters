class Income < ApplicationRecord
  belongs_to :user
  has_many :income_events, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :estimated_amount, numericality: { greater_than_or_equal_to: 0 }

  # Nice options for the frequency dropdown later
  FREQUENCIES = %w[weekly bi_weekly monthly irregular].freeze
  validates :frequency, inclusion: { in: FREQUENCIES }

  # Auto-create validations
  # When auto_create is true, automatically creates income_events using estimated_amount as actual_amount
  # When auto_create is false, user must manually create events and enter actual_amount (which may differ from estimated_amount)
  validates :auto_day_of_month, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 31 }, allow_nil: true
  validates :auto_day_of_month, presence: true, if: -> { auto_create? }

  scope :active, -> { where(active: true) }
  scope :auto_create, -> { where(auto_create: true) }
end
