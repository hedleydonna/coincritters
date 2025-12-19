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
    when "bi_weekly"
      "Bi-weekly"
    when "biweekly"
      "Bi-weekly"
    when "yearly"
      "Yearly"
    else
      "Monthly" # default
    end
  end

  # Get all due dates for a given month based on frequency
  def events_for_month(month_year)
    return [] unless auto_create? && due_date.present?
    
    begin
      month_start = Date.parse("#{month_year}-01")
      month_end = month_start.end_of_month
      
      events = []
      
      # Adjust current_date to be within the target month if needed
      if frequency == "monthly"
        # Monthly: one event per month on the due_date (or last day if due_date exceeds month length)
        day = [due_date.day, month_end.day].min
        event_date = Date.new(month_start.year, month_start.month, day)
        events << event_date if event_date >= month_start && event_date <= month_end
      elsif frequency == "bi_weekly" || frequency == "biweekly"
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
      elsif frequency == "yearly"
        # Yearly: one event per year on the due_date
        event_date = Date.new(month_start.year, due_date.month, [due_date.day, month_end.day].min)
        events << event_date if event_date >= month_start && event_date <= month_end
      end
      
      events.sort
    rescue => e
      Rails.logger.error "Error in events_for_month for expense_template #{id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      []
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

