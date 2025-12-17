# Income Template Model Documentation

## Overview

The IncomeTemplate model represents income sources for users in the CoinCritters application. Each income source tracks a named income stream (e.g., "Salary", "Freelance Work") with its estimated amount, frequency, and active status. Income templates are similar to expense templates in that they define recurring patterns, while income events represent actual money received.

## Database Table

**Table Name:** `income_templates`

### Schema

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | Primary Key | Auto-incrementing unique identifier |
| `user_id` | bigint | NOT NULL | References the user who owns this income template (referential integrity enforced at model level) |
| `name` | string | NOT NULL | Name of the income source (e.g., "Salary", "Freelance") |
| `frequency` | string | NOT NULL, Default: "monthly" | How often this income is received |
| `estimated_amount` | decimal(12,2) | NOT NULL, Default: 0.0 | Estimated amount of income |
| `active` | boolean | NOT NULL, Default: true | Legacy field (not used for soft deletion) |
| `auto_create` | boolean | NOT NULL, Default: false | If `true`, automatically creates income events based on frequency and due_date |
| `deleted_at` | datetime | Nullable | Timestamp when template was soft deleted (NULL = active) |
| `due_date` | date | Nullable | Date when income is typically received (required if `auto_create` is `true`). Used to calculate event dates based on frequency. |
| `last_payment_to_next_month` | boolean | NOT NULL, Default: false | If `true`, the last payment of each month will automatically be deferred to next month's budget |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Last update timestamp |

### Indexes

- **User ID Index**: Index on `user_id` for fast user lookups
- **User ID + Name Index**: Composite index on `[user_id, name]` - NOT unique (allows reusing names after deletion)
- **Deleted At Index**: Index on `deleted_at` - optimized for filtering active/deleted templates

### Referential Integrity

**Note:** This codebase does not use database-level foreign key constraints. Referential integrity is enforced at the model level via `belongs_to` validations in Rails 5+.

- **User**: `belongs_to :user` - enforced via model validation. When a user is deleted, all their income templates are deleted via `dependent: :destroy` in the `User` model association.

Cascade deletion is handled via `dependent: :destroy` in model associations, not database-level foreign keys.

## Model Location

`app/models/income_template.rb`

## Associations

### Belongs To

- **User**: Each income template belongs to exactly one user
  ```ruby
  income_template.user  # Returns the User object
  ```

### Has Many

- **Income Events**: An income template can have many income events
  ```ruby
  income_template.income_events  # Returns collection of IncomeEvent objects
  ```
  - **Dependent Behavior**: `destroy` - when an income template is deleted, all associated events are deleted

### Has Many (from User)

- **User has_many :income_templates**: A user can have multiple income sources
  ```ruby
  user.income_templates  # Returns collection of IncomeTemplate objects
  ```

## Validations

### Name

- **Presence**: Name must be present
- **Uniqueness**: Name must be unique per user among active templates (different users can have income templates with the same name, and deleted templates don't count toward uniqueness)
  ```ruby
  # Valid - same name, different users
  user1.income_templates.create(name: "Salary", ...)
  user2.income_templates.create(name: "Salary", ...)
  
  # Invalid - same name, same user (both active)
  user1.income_templates.create(name: "Salary", ...)
  user1.income_templates.create(name: "Salary", ...)  # Error: name has already been taken
  
  # Valid - can reuse name after deleting
  template1 = user1.income_templates.create(name: "Salary", ...)
  template1.soft_delete!
  user1.income_templates.create(name: "Salary", ...)  # OK - previous one is deleted
  ```

### Estimated Amount

- **Numericality**: Must be a number
- **Greater than or equal to 0**: Cannot be negative
- **Precision**: Up to 12 digits with 2 decimal places (max: 9,999,999,999.99)

### Frequency

- **Inclusion**: Must be one of the predefined frequencies
- **Available Options**:
  - `"weekly"` - Income received weekly
  - `"bi_weekly"` - Income received bi-weekly (every two weeks)
  - `"monthly"` - Income received monthly
  - `"irregular"` - Income with irregular timing

### Auto Create

- **auto_create**: Boolean flag indicating if income events should be automatically created
  - Default: `false` - User must manually create income events
  - When `true`: System will automatically create income events based on frequency and due_date
  - **Requires `due_date`** when set to `true`

- **due_date**: Date when income is typically received (used to calculate event dates)
  - Format: Date (YYYY-MM-DD)
  - `nil` allowed when `auto_create` is `false`
  - **Required** when `auto_create` is `true`
  - Used with `frequency` to calculate all occurrences in a month (e.g., bi-weekly starting on due_date)

- **last_payment_to_next_month**: Boolean flag indicating if the last payment of each month should be deferred
  - Default: `false` - All payments count in the month received
  - When `true`: The last payment of each month automatically gets `apply_to_next_month: true` on the income event
  - Useful for late-month paychecks you want to hold for next month's expenses

## Default Scope

- `default_scope -> { where(deleted_at: nil).order(:name) }` - All queries exclude deleted templates and are ordered alphabetically by name by default. Use `.with_deleted` or `.unscoped` to access deleted templates.

## Scopes

### Active Scope

Returns only active income sources (redundant with default_scope but explicit):

```ruby
user.income_templates.active  # Returns only income templates where deleted_at IS NULL
```

**Usage:**
- Filter active income sources (though default_scope already does this)
- Explicitly show intent in code

### Deleted Scope

Returns only deleted income templates:

```ruby
IncomeTemplate.with_deleted.deleted  # Returns only income templates where deleted_at IS NOT NULL
```

**Usage:**
- Access deleted templates for restoration
- Historical reporting

### With Deleted Scope

Removes the `deleted_at` filter from default_scope:

```ruby
IncomeTemplate.with_deleted  # Returns all templates including deleted ones
```

**Usage:**
- Access all templates including deleted
- Required before using `.deleted` scope

### Auto Create Scope

Returns only income templates that are configured for automatic event creation:

```ruby
user.income_templates.auto_create  # Returns only income templates where auto_create: true
```

**Usage:**
- Find income templates that need automatic event generation
- Process scheduled income events
- Display auto-configured income templates in UI

## Constants

### FREQUENCIES

Array of valid frequency values:
```ruby
IncomeTemplate::FREQUENCIES
# => ["weekly", "bi_weekly", "monthly", "irregular"]
```

**Usage:**
- Populate frequency dropdowns in forms
- Validate frequency values
- Display frequency options in UI

## Default Values

- **frequency**: `"monthly"` - Most common income frequency
- **estimated_amount**: `0.0` - Safe default until user enters amount
- **active**: `true` - New income templates are active by default
- **auto_create**: `false` - Manual event creation by default (user must acknowledge income)
- **due_date**: `nil` - No automatic date specified by default (required when auto_create is true)
- **last_payment_to_next_month**: `false` - All payments count in month received by default

## Usage Examples

### Creating an Income Template

```ruby
# Basic creation (manual event creation)
income_template = IncomeTemplate.create!(
  user: current_user,
  name: "Salary",
  frequency: "monthly",
  estimated_amount: 5000.00
)

# With all options (manual event creation)
income_template = IncomeTemplate.create!(
  user: current_user,
  name: "Freelance Work",
  frequency: "irregular",
  estimated_amount: 1500.50,
  active: true
)

# Auto-create income template (automatically creates events monthly on the 1st)
income_template = IncomeTemplate.create!(
  user: current_user,
  name: "Regular Salary",
  frequency: "monthly",
  estimated_amount: 5000.00,
  auto_create: true,
  due_date: Date.parse("2025-12-01"),
  last_payment_to_next_month: false
)

# Auto-create bi-weekly income template with last payment deferred
income_template = IncomeTemplate.create!(
  user: current_user,
  name: "Bi-weekly Salary",
  frequency: "bi_weekly",
  estimated_amount: 2600.00,
  auto_create: true,
  due_date: Date.parse("2025-12-01"),
  last_payment_to_next_month: true  # Last pay of month goes to next month
)
```

### Querying Income Templates

```ruby
# All income templates for a user
user.income_templates

# Only active income templates
user.income_templates.active

# Find specific income template
income_template = user.income_templates.find_by(name: "Salary")

# Check if income template exists
user.income_templates.exists?(name: "Salary")
```

### Updating Income Template

```ruby
# Update amount
income_template.update(estimated_amount: 5500.00)

# Soft delete income template
income_template.soft_delete!

# Restore deleted template
income_template.restore!

# Change frequency
income_template.update(frequency: "bi_weekly")
```

### Soft Deleting Income Template

```ruby
# Soft delete single income template
income_template.soft_delete!
# Sets deleted_at timestamp, preserves all associated income events

# Restore deleted template
income_template.restore!
# Clears deleted_at, makes template active again

# Access deleted templates
deleted_templates = IncomeTemplate.with_deleted.deleted

# Delete all income templates for user (when user is deleted, cascade handles this)
user.destroy  # Automatically deletes all associated income templates
```

## Business Rules

1. **Unique Names Per User (Active Only)**: Users cannot have duplicate income source names among active templates. Deleted templates don't count toward uniqueness, allowing name reuse.
2. **Different Users, Same Names**: Multiple users can have income templates with the same name (e.g., both users can have "Salary")
3. **Soft Delete with `deleted_at`**: Deleted income templates are retained but hidden from normal views. They can be restored using `restore!` method.
4. **Cascade Delete**: Deleting a user automatically deletes all their income templates (hard delete via `dependent: :destroy`)
5. **Non-Negative Amounts**: Income amounts cannot be negative (for expenses, use a separate model)
6. **Default Scope Filtering**: The default scope automatically excludes deleted templates. Use `.with_deleted` to access all templates including deleted ones.
7. **Filtered Views**: Income events from deleted templates are automatically filtered out from the money-in list.
6. **Auto Create Requirements**: 
   - When `auto_create` is `true`, `due_date` must be provided
   - When `auto_create` is `false`, `due_date` can be `nil`
   - Auto-create is intended for predictable income where `estimated_amount` consistently matches the actual amount received
   - Manual entry (`auto_create: false`) is for variable income where actual amounts may differ from estimates
7. **Auto Create Behavior**:
   - When `auto_create` is enabled, the system automatically creates `IncomeEvent` records based on `frequency` and `due_date`
   - For monthly: Creates one event per month on the due_date day
   - For bi-weekly: Creates 2-3 events per month (every 14 days from due_date)
   - For weekly: Creates 4-5 events per month (every 7 days from due_date)
   - Events are created with `actual_amount: 0` initially (unless due_date is today, then pre-filled with estimated_amount)
   - User can then mark as "Received" or edit the amount when money arrives
8. **Last Payment Deferral**:
   - When `last_payment_to_next_month` is `true`, the last payment of each month automatically gets `apply_to_next_month: true`
   - This defers that payment to next month's budget instead of current month
   - Useful for late-month paychecks you want to hold for next month's expenses

## Auto-Create Feature

### Concept

The auto-create feature allows users to configure income templates that automatically generate `IncomeEvent` records without manual intervention. This addresses two different use cases:

- **Predictable, Consistent Income** (`auto_create: true`): For income where the amount is always the same (e.g., fixed monthly salary). The system automatically creates an income event on the specified day, using the income template's `estimated_amount` as the event's `actual_amount`. No manual entry needed.
  
- **Variable Income** (`auto_create: false`): For income where the amount varies month-to-month (e.g., variable paychecks, commissions). The user must manually create income events and enter the `actual_amount` received, which may differ from the `estimated_amount`.

**Key Difference**: 
- Auto-create uses `estimated_amount` directly as `actual_amount` (assumes they match)
- Manual entry allows user to specify the `actual_amount` received (which may differ from `estimated_amount`)

### How It Works

1. **User Configuration**: 
   - For predictable income: User sets `auto_create: true` and specifies `due_date` and `frequency`
   - For variable income: User sets `auto_create: false` (or leaves it as default `false`)
   - Optionally set `last_payment_to_next_month: true` to defer last payment of each month

2. **Automatic Event Generation** (for `auto_create: true`): 
   - System automatically creates `IncomeEvent` records based on `frequency` and `due_date`
   - Calculates all occurrences in the month (e.g., bi-weekly = 2-3 events, weekly = 4-5 events)
   - Events are created with `actual_amount: 0` initially (user marks as "Received" when money arrives)
   - If `due_date` is today, `actual_amount` is pre-filled with `estimated_amount`
   - If `last_payment_to_next_month` is `true`, the last event of the month gets `apply_to_next_month: true`
   - Events are only created from today forward for current month (not past dates)

3. **Manual Event Creation** (for `auto_create: false`):
   - User manually creates `IncomeEvent` records when income is received
   - User enters the `actual_amount` received (which may differ from `estimated_amount`)
   - Allows flexibility for variable income amounts

4. **Manual Override**: Users can still manually create, edit, or delete auto-generated events if needed

### Use Cases

- **Fixed Monthly Salary**: User always gets paid exactly $5,000 on the 1st → `auto_create: true, due_date: Date.parse("2025-12-01"), frequency: "monthly", estimated_amount: 5000.00`
  - System creates one event per month on the 1st with `actual_amount: 0` (user marks as "Received" when paid)
  
- **Bi-weekly Salary with Deferral**: User gets paid bi-weekly, wants last pay of month to go to next month → `auto_create: true, due_date: Date.parse("2025-12-01"), frequency: "bi_weekly", last_payment_to_next_month: true`
  - System creates 2-3 events per month based on due_date
  - Last event of month automatically gets `apply_to_next_month: true`
  
- **Variable Paycheck**: User's paycheck varies (e.g., $4,800-$5,200) due to hours/bonuses → `auto_create: false`
  - User manually creates events each month and enters the actual amount received
  - `estimated_amount` serves as a budget estimate, but `actual_amount` is entered per event
  
- **Consistent Freelance Payment**: User always receives exactly $2,000 on the 15th from a regular client → `auto_create: true, due_date: Date.parse("2025-12-15"), frequency: "monthly"`
  
- **Irregular Freelance Income**: User's freelance work varies significantly in amount and timing → `auto_create: false`
  - User manually creates events with varying amounts as income is received

### Implementation Notes

- Auto-creation happens when user visits Money Map or Income This Month page
- System checks for income templates where `auto_create: true` and `active: true`
- Creates events for current and next month if not already created
- Handles edge cases (end of month, leap years, different month lengths)
- Events are only created from today forward for current month (not past dates)
- Users can review, edit, or delete auto-generated events

## Instance Methods

### `soft_delete!`

Soft deletes the income template by setting `deleted_at` to current time.

**Returns:**
- Boolean - true if update succeeds

**Example:**
```ruby
income_template.soft_delete!
income_template.deleted?  # => true
income_template.deleted_at  # => 2026-01-15 10:30:00 UTC
```

### `restore!`

Restores a deleted income template by clearing `deleted_at`.

**Returns:**
- Boolean - true if update succeeds

**Example:**
```ruby
income_template.restore!
income_template.active?  # => true
income_template.deleted_at  # => nil
```

### `deleted?`

Checks if the income template is deleted.

**Returns:**
- Boolean - true if `deleted_at` is present

**Example:**
```ruby
income_template.deleted?  # => false (if active)
income_template.soft_delete!
income_template.deleted?  # => true
```

### `active?`

Checks if the income template is active (not deleted).

**Returns:**
- Boolean - true if `deleted_at` is nil

**Example:**
```ruby
income_template.active?  # => true
income_template.soft_delete!
income_template.active?  # => false
```

### `events_for_month(month_year)`

Calculates all income event dates for a given month based on frequency and due_date.

**Parameters:**
- `month_year` (String) - Month in YYYY-MM format (e.g., "2025-12")

**Returns:**
- Array of Date objects representing when income events should occur

**Examples:**
```ruby
income_template = IncomeTemplate.create!(
  user: user,
  name: "Bi-weekly Salary",
  frequency: "bi_weekly",
  due_date: Date.parse("2025-12-01"),
  auto_create: true
)

# Get events for December 2025
dates = income_template.events_for_month("2025-12")
# => [2025-12-01, 2025-12-15, 2025-12-29]
```

### `expected_amount_for_month(month_year)`

Calculates the total expected income for a given month.

**Parameters:**
- `month_year` (String) - Month in YYYY-MM format

**Returns:**
- BigDecimal - Total expected amount (number of events × estimated_amount)

**Examples:**
```ruby
income_template = IncomeTemplate.create!(
  user: user,
  name: "Bi-weekly Salary",
  frequency: "bi_weekly",
  due_date: Date.parse("2025-12-01"),
  estimated_amount: 2600.00,
  auto_create: true
)

# Calculate expected for December (3 pays)
expected = income_template.expected_amount_for_month("2025-12")
# => 7800.00 (3 × 2600.00)
```

### `last_payment_to_next_month?`

Returns whether the last payment of each month should be deferred to next month.

**Returns:**
- Boolean - true if last payment should be deferred

## Future Enhancements

Potential additions to the IncomeTemplate model:

- **Notes/Description**: Additional details about the income source
- **Start Date / End Date**: Track when income starts and ends
- **Categories/Tags**: Categorize income types
- **Currency**: Support for multiple currencies
- **Income History**: Track income changes over time

## Related Models

- **User**: Parent model - each income template belongs to a user
- **IncomeEvent**: Child model - income templates can have many income events
- **ExpenseTemplate**: Similar template model for expenses
- **MonthlyBudget**: Uses income templates to calculate expected income

## Database Constraints

- Foreign key constraint ensures referential integrity
- Unique index prevents duplicate income names per user
- Composite indexes optimize common queries
- Cascade delete maintains data consistency

---

**Last Updated**: January 2026

