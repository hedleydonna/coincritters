# Income Event Model Documentation

## Overview

The Income Event model represents actual income received events in the Willow application. Each income event records a specific instance of income received, including the amount, when it was received, and which month it should be attributed to. Income events can be optionally linked to an income source and include a free-form income type string for categorization.

## Database Table

**Table Name:** `income_events`

### Schema

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | Primary Key | Auto-incrementing unique identifier |
| `user_id` | bigint | NOT NULL, Foreign Key | References the user who received this income |
| `income_id` | bigint | Foreign Key (nullable) | Optionally references the income source this event came from |
| `income_type` | string | NOT NULL, Default: "Paycheck" | Free-form string categorizing the income type (e.g., "Paycheck", "Bonus", "Freelance") |
| `month_year` | string | NOT NULL | Month/year the income was actually received (format: YYYY-MM) |
| `assigned_month_year` | string | Nullable | Month/year this income should be attributed to (format: YYYY-MM) |
| `received_on` | date | NOT NULL | Specific date the income was received |
| `actual_amount` | decimal(12,2) | NOT NULL, Default: 0.0 | Actual amount of income received |
| `notes` | text | Nullable | Optional notes about this income event |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Last update timestamp |

### Indexes

- **User ID + Month Year Index**: Composite index on `[user_id, month_year]` - optimized for finding events by user and month
- **User ID + Assigned Month Year Index**: Composite index on `[user_id, assigned_month_year]` - for finding events by assigned month
- **Income ID + Month Year Index**: Composite index on `[income_id, month_year]` - for finding events by income source and month
- **Income ID Index**: Index on `income_id` for fast lookups by income source

### Foreign Keys

- **User**: `belongs_to :user` with `on_delete: :cascade` - when a user is deleted, all their income events are deleted
- **Income**: `belongs_to :income, optional: true` with `on_delete: :cascade` - when an income source is deleted, associated events are deleted

## Model Location

`app/models/income_event.rb`

## Associations

### Belongs To

- **User**: Each income event belongs to exactly one user
  ```ruby
  income_event.user  # Returns the User object
  ```

- **Income** (optional): An income event can optionally be linked to an income source
  ```ruby
  income_event.income  # Returns Income object or nil
  ```

### Has Many (from User)

- **User has_many :income_events**: A user can have multiple income events
  ```ruby
  user.income_events  # Returns collection of IncomeEvent objects
  ```
  - **Dependent Behavior**: `destroy` - when a user is deleted, all their income events are deleted

### Has Many (from Income)

- **Income has_many :income_events**: An income source can have multiple events
  ```ruby
  income.income_events  # Returns collection of IncomeEvent objects
  ```
  - **Dependent Behavior**: `destroy` - when an income is deleted, all associated events are deleted

## Validations

### Presence Validations

- `validates :month_year, presence: true`:
  - The `month_year` field must be present.

- `validates :received_on, presence: true`:
  - The `received_on` field must be present.

- `validates :income_type, presence: true`:
  - The `income_type` field must be present.

### Format Validations

- `validates :month_year, format: { with: /\A\d{4}-\d{2}\z/, message: "must be in YYYY-MM format" }`:
  - `month_year` must match the pattern `YYYY-MM` (e.g., "2025-12").
  - Valid examples: "2025-01", "2025-12", "2024-03"
  - Invalid examples: "2025-1", "25-12", "December 2025"

- `validates :assigned_month_year, format: { with: /\A\d{4}-\d{2}\z/, message: "must be in YYYY-MM format" }, allow_blank: true`:
  - `assigned_month_year` must match the pattern `YYYY-MM` if present.
  - Can be blank (optional field).

### Numericality Validations

- `validates :actual_amount, numericality: { greater_than_or_equal_to: 0 }`:
  - `actual_amount` must be a number.
  - `actual_amount` must be zero or a positive value (cannot be negative).

### Association Validations

- Requires `user` (validated by `belongs_to :user`)
- `income` is optional (validated by `belongs_to :income, optional: true`)

## Business Rules

1. **Required Associations**: Every income event must have a user. The income source is optional.

2. **Income Type**: The `income_type` is a free-form string field (not a foreign key). It defaults to "Paycheck" if not specified. Users can enter any value they want (e.g., "Salary", "Bonus", "Freelance", "Investment", "Gift").

3. **Date Formatting**: Both `month_year` and `assigned_month_year` must be in `YYYY-MM` format if provided.

4. **Non-Negative Amounts**: Income amounts cannot be negative (though zero is allowed).

5. **Cascade Deletion**: 
   - Deleting a user deletes all their income events
   - Deleting an income source deletes all associated income events

6. **Default Values**: 
   - New income events default to `actual_amount: 0.0` if not specified
   - New income events default to `income_type: "Paycheck"` if not specified

## Usage Examples

### Creating an Income Event

```ruby
user = User.first

income_event = user.income_events.create(
  income_type: "Paycheck",
  month_year: "2025-12",
  received_on: Date.today,
  actual_amount: 4500.00
)
# => #<IncomeEvent id: 1, user_id: 1, income_type: "Paycheck", month_year: "2025-12", ...>
```

### Creating with Income Source

```ruby
user = User.first
income = user.incomes.first

income_event = user.income_events.create(
  income: income,
  income_type: "Salary",
  month_year: "2025-12",
  received_on: Date.today,
  actual_amount: 4500.00
)
```

### Creating with Custom Income Type

```ruby
income_event = user.income_events.create(
  income_type: "Year-end Bonus",
  month_year: "2025-12",
  received_on: Date.today,
  actual_amount: 5000.00,
  notes: "Annual performance bonus"
)
```

### Creating with Assigned Month

```ruby
income_event = user.income_events.create(
  income_type: "Paycheck",
  month_year: "2025-12",        # Received in December
  assigned_month_year: "2026-01", # But attribute to January
  received_on: Date.parse("2025-12-28"),
  actual_amount: 4500.00,
  notes: "Salary received early for January"
)
```

### Retrieving Events by Month

```ruby
user = User.first
december_events = user.income_events.where(month_year: "2025-12")
# => #<ActiveRecord::Relation [#<IncomeEvent ... month_year: "2025-12">, ...]>
```

### Retrieving Events by Income Type

```ruby
user = User.first
paycheck_events = user.income_events.where(income_type: "Paycheck")
# => #<ActiveRecord::Relation [#<IncomeEvent ... income_type: "Paycheck">, ...]>
```

### Calculating Total for a Month

```ruby
user = User.first
total_december = user.income_events
  .where(month_year: "2025-12")
  .sum(:actual_amount)
# => #<BigDecimal "12345.67">
```

### Handling Validation Errors

```ruby
user = User.first

# Invalid month_year format
invalid_event = user.income_events.create(
  income_type: "Paycheck",
  month_year: "December 2025",
  received_on: Date.today
)
# => #<IncomeEvent ... errors: {:month_year=>["must be in YYYY-MM format"]}>

# Negative amount
invalid_amount = user.income_events.create(
  income_type: "Paycheck",
  month_year: "2025-12",
  received_on: Date.today,
  actual_amount: -100.00
)
# => #<IncomeEvent ... errors: {:actual_amount=>["must be greater than or equal to 0"]}>

# Missing required fields
missing_fields = user.income_events.create(
  income_type: "Paycheck"
)
# => #<IncomeEvent ... errors: {:month_year=>["can't be blank"], :received_on=>["can't be blank"]}>
```

## Key Concepts

### month_year vs assigned_month_year

- **month_year**: The actual month and year when the income was received (required)
- **assigned_month_year**: The month and year this income should be attributed to for reporting/budgeting purposes (optional)

This distinction allows for scenarios like:
- Receiving December salary early (month_year: "2025-11", assigned_month_year: "2025-12")
- Receiving January payment in late December (month_year: "2025-12", assigned_month_year: "2026-01")

### Income Type as String Field

The `income_type` field is a free-form string, not a foreign key. This provides flexibility:
- Users can create any income type name they want
- No need to pre-define categories
- Common examples: "Paycheck", "Salary", "Bonus", "Freelance", "Investment", "Rental", "Gift"
- Default value is "Paycheck" if not specified

### Relationship to Income Sources

Income events can optionally be linked to income sources (`income`). This allows tracking which events came from which planned income sources. However, events can also exist independently, allowing for one-time or unexpected income.

## Admin Dashboard

Income events can be managed through the admin dashboard:
- **View All**: `/admin/income_events`
- **View Details**: `/admin/income_events/:id`
- **Edit**: `/admin/income_events/:id/edit`
- **Create**: `/admin/income_events/new`

The admin dashboard displays:
- Total count of income events
- Recent income events
- Ability to create, edit, and delete events

## Migration History

- `20251209214918_create_income_events.rb` - Initial income_events table creation
- Note: The `income_type` field was changed from a foreign key relationship to a string field

## Future Enhancements

- **Bulk Import**: Allow importing multiple income events from CSV/Excel
- **Recurring Events**: Auto-generate events based on income source frequency
- **Reporting**: Generate reports by month, type, or income source
- **Attachments**: Allow uploading receipts or documentation
- **Tags/Labels**: Add additional categorization beyond income type
- **Forecasting**: Predict future income based on historical events
- **Notifications**: Alert users when expected income hasn't been received
- **Income Type Suggestions**: Auto-suggest common income types based on user's history

---

**Last Updated**: December 2025
