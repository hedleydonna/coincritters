# Income Event Model Documentation

## Overview

The Income Event model represents actual income received events in the Willow application. Each income event records a specific instance of income received, including the amount, when it was received, and which month it should be attributed to. Income events are typically linked to an income source (from the `incomes` table), and the event's display name comes from the linked income's `name` field. For one-off or custom income events that don't correspond to a regular income source (such as a birthday present or unexpected windfall), the `custom_label` field provides a manual label when no income record is linked.

## Database Table

**Table Name:** `income_events`

### Schema

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | Primary Key | Auto-incrementing unique identifier |
| `user_id` | bigint | NOT NULL | References the user who received this income (referential integrity enforced at model level) |
| `income_id` | bigint | Nullable | Optionally references the income source this event came from (referential integrity enforced at model level). When present, the event's display name comes from `incomes.name`. |
| `custom_label` | string | Nullable| Manual label for one-off income events that don't correspond to an income record (e.g., "Birthday Gift", "One-time Bonus"). Only used when `income_id` is null. When `income_id` is present, this field is typically `nil`. |
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

### Referential Integrity

**Note:** This codebase does not use database-level foreign key constraints. Referential integrity is enforced at the model level via `belongs_to` validations in Rails 5+.

- **User**: `belongs_to :user` - enforced via model validation. When a user is deleted, all their income events are deleted via `dependent: :destroy` in the `User` model association.
- **Income**: `belongs_to :income, optional: true` - enforced via model validation. When an income source is deleted, associated events are deleted via `dependent: :destroy` in the `Income` model association.

Cascade deletion is handled via `dependent: :destroy` in model associations, not database-level foreign keys.

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
  income_event.income&.name  # Returns the income name if linked, or nil
  ```
  
  When an income event is linked to an income source, the event's display name should come from the income's `name` field (`income.name`). The `custom_label` field is only used when there is no linked income record (for one-off or custom events).

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

- `validates :custom_label, presence: true, if: -> { income_id.nil? }`:
  - The `custom_label` field must be present **only when** `income_id` is null (i.e., for custom/one-off events).
  - When an event is linked to an income source (`income_id` is present), `custom_label` can be `nil` since the display name comes from the income's name field.

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

## Instance Methods

### `display_name`

Returns the display name for the income event.

**Logic:**
- If the income event is linked to an income source (`income_id` is present), returns `income.name`.
- If the income event is not linked to an income source (`income_id` is `nil`), returns `custom_label`.
- Returns `nil` only if both `income` and `custom_label` are `nil` (though this should be prevented by validation).

**Example:**
```ruby
# When linked to an income source
income = Income.create!(user: user, name: "Monthly Salary", frequency: "monthly", estimated_amount: 5000.00)
event = IncomeEvent.create!(user: user, income: income, month_year: "2025-12", received_on: Date.today)
event.display_name # => "Monthly Salary"

# When using custom label
event = IncomeEvent.create!(user: user, custom_label: "Birthday Gift", month_year: "2025-12", received_on: Date.today)
event.display_name # => "Birthday Gift"
```

## Business Rules

1. **Required Associations**: Every income event must have a user. The income source is optional.

2. **Display Name Logic**: 
   - When an income event is linked to an income source (`income_id` is present), the event's display name comes from the linked income's `name` field (`income.name`). In this case, `custom_label` can be `nil`.
   - When an income event is NOT linked to an income source (`income_id` is null), the `custom_label` field is required and provides the display name.
   - `custom_label` is nullable in the database but required when there's no linked income record.
   - Use the `display_name` instance method to get the appropriate display name (see Instance Methods section above).

3. **Custom Events**: One-off income events (like birthday presents, unexpected bonuses, tax refunds, etc.) that don't correspond to regular income sources can be created without linking to an `incomes` record. These events require the `custom_label` field for their display name.

4. **Date Formatting**: Both `month_year` and `assigned_month_year` must be in `YYYY-MM` format if provided.

5. **Non-Negative Amounts**: Income amounts cannot be negative (though zero is allowed).

6. **Cascade Deletion**: 
   - Deleting a user deletes all their income events
   - Deleting an income source deletes all associated income events

7. **Default Values**: 
   - New income events default to `actual_amount: 0.0` if not specified


## Usage Examples

### Creating an Income Event Linked to an Income Source

```ruby
user = User.first
income = user.incomes.first  # e.g., "Monthly Salary"

# When linked to an income, the event's display name comes from income.name
# custom_label can be nil for linked events
income_event = user.income_events.create(
  income_id: income,
  month_year: "2025-12",
  received_on: Date.today,
  actual_amount: 4500.00,
  custom_label: nil  # Optional - can be nil when income is present
)
# The display name for this event would be income.name (e.g., "Monthly Salary")
# custom_label is not required when income_id is present
```

### Creating a Custom One-Off Income Event

```ruby
# For events that don't correspond to a regular income source
# (e.g., birthday gifts, unexpected bonuses, tax refunds)
# custom_label is REQUIRED when income is nil
income_event = user.income_events.create(
  income_id: nil,  # No linked income record
  custom_label: "Birthday Gift",  # Required when income_id is nil
  month_year: "2025-12",
  received_on: Date.today,
  actual_amount: 500.00,
  notes: "Gift from family"
)
# The display name for this event would be "Birthday Gift" (from custom_label)

# If custom_label is not provided, it defaults to "Other"
income_event_with_default = user.income_events.create(
  income_id: nil,
  month_year: "2025-12",
  received_on: Date.today,
  actual_amount: 300.00
)
# custom_label will default to "Other" if not specified
```

### Creating Another Custom Event

```ruby
income_event = user.income_events.create(
  income_id: nil,
  custom_label: "Tax Refund",
  month_year: "2025-12",
  received_on: Date.today,
  actual_amount: 1200.00,
  notes: "State tax refund for 2024"
)
```

### Creating with Assigned Month

```ruby
income = user.incomes.first  # e.g., "Monthly Salary"

income_event = user.income_events.create(
  income_id: income,
  month_year: "2025-12",        # Received in December
  assigned_month_year: "2026-01", # But attribute to January
  received_on: Date.parse("2025-12-28"),
  actual_amount: 4500.00,
  notes: "Salary received early for January"
)
# Display name comes from income.name via display_name method
income_event.display_name  # => "Monthly Salary"
```

### Getting Display Name

```ruby
# When linked to an income source, display_name returns income.name
income = user.incomes.first  # e.g., "Monthly Salary"
income_event = user.income_events.create(
  income: income,
  month_year: "2025-12",
  received_on: Date.today,
  actual_amount: 4500.00
)
income_event.display_name  # => "Monthly Salary"

# When using custom label, display_name returns custom_label
income_event = user.income_events.create(
  custom_label: "Birthday Gift",
  month_year: "2025-12",
  received_on: Date.today,
  actual_amount: 500.00
)
income_event.display_name  # => "Birthday Gift"
```

### Retrieving Events by Month

```ruby
user = User.first
december_events = user.income_events.where(month_year: "2025-12")
# => #<ActiveRecord::Relation [#<IncomeEvent ... month_year: "2025-12">, ...]>
```

### Retrieving Custom Events (Events Without Linked Income)

```ruby
user = User.first
custom_events = user.income_events.where(income_id: nil)
# => #<ActiveRecord::Relation [#<IncomeEvent ... custom_label: "Birthday Gift">, ...]>

# Or by custom_label
birthday_events = user.income_events.where(custom_label: "Birthday Gift")
```

### Retrieving Events by Linked Income

```ruby
income = user.incomes.first
income_events = income.income_events
# => #<ActiveRecord::Relation [#<IncomeEvent ... income_id: 1>, ...]>
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
  income_id: nil,
  custom_label: "Paycheck",
  month_year: "December 2025",
  received_on: Date.today
)
# => #<IncomeEvent ... errors: {:month_year=>["must be in YYYY-MM format"]}>

# Negative amount
invalid_amount = user.income_events.create(
  income_id: nil,
  custom_label: "Paycheck",
  month_year: "2025-12",
  received_on: Date.today,
  actual_amount: -100.00
)
# => #<IncomeEvent ... errors: {:actual_amount=>["must be greater than or equal to 0"]}>

# Missing custom_label when income is nil
missing_custom_label = user.income_events.create(
  income_id: nil,
  month_year: "2025-12",
  received_on: Date.today
)
# custom_label defaults to "Other", so this is valid

# Missing custom_label when income is nil and explicitly set to nil (invalid)
missing_custom_label_invalid = user.income_events.create(
  income_id: nil,
  custom_label: nil,
  month_year: "2025-12",
  received_on: Date.today
)
# => #<IncomeEvent ... errors: {:custom_label=>["can't be blank"]}>

# Missing required fields
missing_fields = user.income_events.create(
  custom_label: "Paycheck"
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

When using `assigned_month_year`, the event is still linked to its income source (if applicable), but the income is attributed to a different month for budgeting/reporting purposes.

### Display Name Logic

The display name for an income event is determined by the `display_name` instance method (see Instance Methods section above):

- **If `income_id` is present**: Display name comes from the linked income's `name` field (`income.name`). In this case, `custom_label` can be `nil` and is not required.
- **If `income_id` is null**: Display name comes from the `custom_label` field, which is required and cannot be `nil`.

This design allows for two types of income events:
1. **Regular income events**: Linked to an income source from the `incomes` table. These represent actual occurrences of planned/recurring income (e.g., monthly salary, weekly freelance payments). The name is automatically derived from the income source via the `display_name` method. For these events, `custom_label` is optional and typically `nil`.

2. **Custom/one-off events**: Not linked to any income source. These represent unexpected or one-time income (e.g., birthday gifts, tax refunds, one-time bonuses). These events **require** a `custom_label` to provide a display name since there's no linked income record to reference. The `display_name` method will return the `custom_label` value.

### Relationship to Income Sources

Most income events should be linked to an income source (`income`) representing the planned/recurring income. This allows:
- Automatic naming from the income source
- Tracking which events came from which planned income sources
- Analyzing actual vs. estimated income
- Generating recurring events based on income frequency

Custom events (without linked income) are for special cases where the income doesn't fit into regular income categories and doesn't warrant creating a permanent income record.

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
- `20251210174514_rename_income_type_to_custom_label_in_income_events.rb` - Renamed `income_type` to `custom_label`, made the column nullable, and changed default to "Other" to better reflect its purpose as an optional label for custom/one-off events

## Future Enhancements

- **Bulk Import**: Allow importing multiple income events from CSV/Excel
- **Recurring Events**: Auto-generate events based on income source frequency
- **Reporting**: Generate reports by month, type, or income source
- **Attachments**: Allow uploading receipts or documentation
- **Tags/Labels**: Add additional categorization beyond income type
- **Forecasting**: Predict future income based on historical events
- **Notifications**: Alert users when expected income hasn't been received
- **Custom Label Auto-fill**: When creating an event without an income, suggest common custom labels based on user's history

---

**Last Updated**: December 2025
