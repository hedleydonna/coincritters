class Income < ApplicationRecord
  belongs_to :user

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :estimated_amount, numericality: { greater_than_or_equal_to: 0 }

  # Nice options for the frequency dropdown later
  FREQUENCIES = %w[weekly bi_weekly monthly irregular].freeze
  validates :frequency, inclusion: { in: FREQUENCIES }

  scope :active, -> { where(active: true) }
end
