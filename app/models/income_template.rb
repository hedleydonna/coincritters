class IncomeTemplate < ApplicationRecord
  belongs_to :user
  has_many :income_events, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :user_id, conditions: -> { where(deleted_at: nil) } }
  validates :estimated_amount, numericality: { greater_than: 0, message: "must be greater than 0" }

  # Frequency options
  FREQUENCIES = %w[weekly bi_weekly monthly irregular].freeze
  validates :frequency, inclusion: { in: FREQUENCIES }

  # Auto-create validations
  # When auto_create is true, automatically creates income_events using estimated_amount as actual_amount
  # When auto_create is false, user must manually create events and enter actual_amount (which may differ from estimated_amount)
  validates :due_date, presence: true, if: -> { auto_create? }

  # Default scope excludes deleted items
  default_scope -> { where(deleted_at: nil).order(:name) }

  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { unscope(where: :deleted_at).where.not(deleted_at: nil) }
  scope :with_deleted, -> { unscope(where: :deleted_at) }
  scope :auto_create, -> { where(auto_create: true) }
  
  # Recalculate affected budgets when estimated_amount changes
  after_update :recalculate_affected_budgets, if: :saved_change_to_estimated_amount?
  
  # Check if last payment should be deferred to next month
  def last_payment_to_next_month?
    last_payment_to_next_month == true
  end

  # Calculate how many income events should be created for a given month
  # based on frequency and due_date
  def events_for_month(month_year)
    return [] unless auto_create? && due_date.present?
    
    month_start = Date.parse("#{month_year}-01")
    month_end = month_start.end_of_month
    
    events = []
    current_date = due_date
    
    # Adjust current_date to be within the target month if needed
    # If due_date is the 15th, we want to find all occurrences in the month
    if frequency == "monthly"
      # Monthly: one event per month on the due_date (or last day if due_date exceeds month length)
      day = [due_date.day, month_end.day].min
      event_date = Date.new(month_start.year, month_start.month, day)
      events << event_date if event_date >= month_start && event_date <= month_end
    elsif frequency == "bi_weekly"
      # Bi-weekly: find all occurrences in the month (every 14 days)
      # Start from the first occurrence in or before the month
      start_date = due_date
      
      # Go backwards to find the first occurrence before or at month_start
      while start_date > month_start
        start_date -= 14.days
      end
      
      # If we went too far back, go forward to the first occurrence in the month
      while start_date < month_start
        start_date += 14.days
      end
      
      # Now add all occurrences in the month
      current = start_date
      while current <= month_end
        events << current
        current += 14.days
      end
    elsif frequency == "weekly"
      # Weekly: find all occurrences in the month (every 7 days)
      start_date = due_date
      while start_date > month_start
        start_date -= 7.days
      end
      while start_date < month_start
        start_date += 7.days
      end
      
      current = start_date
      while current <= month_end
        events << current
        current += 7.days
      end
    end
    
    events.sort
  end

  # Calculate expected total income for a month
  def expected_amount_for_month(month_year)
    events_count = events_for_month(month_year).count
    events_count * estimated_amount
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

  private

  # Recalculate affected budgets when estimated_amount changes
  # Note: Since expected_income is a calculated method, it will automatically
  # use the new estimated_amount when accessed. This callback is here for
  # documentation and in case we add caching in the future.
  def recalculate_affected_budgets
    # Find all months that have events from this template (current and future)
    current_month = Time.current.strftime("%Y-%m")
    affected_months = income_events
      .where("month_year >= ?", current_month)
      .distinct
      .pluck(:month_year)
    
    # Also find months affected by deferred events from previous month
    prev_month = (Date.parse("#{current_month}-01") - 1.month).strftime("%Y-%m")
    deferred_events = income_events.where(month_year: prev_month, apply_to_next_month: true)
    if deferred_events.any?
      # Deferred events count toward the next month
      affected_months << (Date.parse("#{prev_month}-01") + 1.month).strftime("%Y-%m")
    end
    
    # expected_income is a calculated method, so it will automatically use
    # the updated estimated_amount when accessed. No action needed here.
    # This callback ensures the calculation is aware of the change.
  end
end

