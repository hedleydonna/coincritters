# Spending Model Documentation

## Overview

The Spending model represents individual spending transactions within an envelope in the Willow application. This unified model replaces the previous `variable_spending` and `bill_payments` tables, consolidating all spending records regardless of whether they are fixed bills or variable expenses.

## Database Table

**Table Name:** `spendings`

### Schema

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | Primary Key | Auto-incrementing unique identifier |
| `envelope_id` | bigint | NOT NULL, Foreign Key | References the envelope this spending belongs to |
| `amount` | decimal(12,2) | NOT NULL, Default: 0.0 | The amount spent (must be greater than 0) |
| `spent_on` | date | NOT NULL | The date the spending occurred |
| `notes` | text | | Optional notes about the spending |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Last update timestamp |

### Indexes

- **Envelope ID + Spent On Index**: Composite index on `[envelope_id, spent_on]` for fast lookups by envelope and date
- **Envelope ID Index**: Automatically created by `t.references` for foreign key lookups

### Foreign Keys

- `spendings.envelope_id` references `envelopes.id` with `on_delete: :cascade`. If an envelope is deleted, all its spending records are deleted.

## Model Location

`app/models/spending.rb`

## Associations

### Belongs To

- **Envelope**: Each spending record belongs to exactly one envelope
  ```ruby
  spending.envelope  # Returns the Envelope object
  ```

### Has One Through

- **Monthly Budget**: Each spending record has access to its monthly budget through the envelope
  ```ruby
  spending.monthly_budget  # Returns the MonthlyBudget object
  ```

- **User**: Each spending record has access to its user through the monthly budget
  ```ruby
  spending.user  # Returns the User object
  ```

## Validations

- **Amount**: 
  - Must be present
  - Must be a number greater than 0
  - Error message: "must be greater than 0"

- **Spent On**: 
  - Must be present

## Scopes

### `recent`
Returns spending records ordered by `spent_on` (descending) and `created_at` (descending).

```ruby
Spending.recent  # Most recent spending first
```

### `for_date(date)`
Returns all spending records for a specific date.

```ruby
Spending.for_date(Date.current)  # All spending today
```

### `for_date_range(start_date, end_date)`
Returns all spending records within a date range (inclusive).

```ruby
Spending.for_date_range(Date.current.beginning_of_month, Date.current.end_of_month)  # All spending this month
```

### `for_envelope(envelope)`
Returns all spending records for a specific envelope.

```ruby
envelope = Envelope.find(1)
Spending.for_envelope(envelope)  # All spending for this envelope
```

## Instance Methods

### `spending_group_name`
Returns the spending group name from the associated envelope (delegated to `envelope.name`).

```ruby
spending.spending_group_name  # e.g., "Groceries", "Rent"
```

### `formatted_amount`
Returns the amount formatted as a currency string using Rails' `number_to_currency` helper. Handles localization and proper currency formatting.

```ruby
spending.formatted_amount  # e.g., "$75.50"
```

### `today?`
Returns `true` if the spending occurred today. Uses `Date.current` for timezone-aware date comparison.

```ruby
spending.today?  # true if spent_on == Date.current
```

### `this_week?`
Returns `true` if the spending occurred this week (Monday through Sunday). Uses `Date.current` for timezone-aware date comparison.

```ruby
spending.this_week?  # true if spent_on is within current week
```

### `this_month?`
Returns `true` if the spending occurred this month. Compares year and month for efficient and accurate month detection.

```ruby
spending.this_month?  # true if spent_on.year == Date.current.year && spent_on.month == Date.current.month
```

### `to_s`
Returns a friendly string representation for debugging and display purposes.

```ruby
spending.to_s  # e.g., "$75.50 on December 15, 2025 – Groceries"
```

## Usage Examples

### Creating a Spending Record

```ruby
envelope = Envelope.find(1)
spending = Spending.create!(
  envelope: envelope,
  amount: 75.50,
  spent_on: Date.current,
  notes: "Weekly grocery shopping"
)
```

### Querying Spending Records

```ruby
# Get recent spending
recent_spending = Spending.recent.limit(10)

# Get spending for a specific date
today_spending = Spending.for_date(Date.current)

# Get spending for this month
monthly_spending = Spending.for_date_range(
  Date.current.beginning_of_month,
  Date.current.end_of_month
)

# Get all spending for a specific envelope
envelope_spending = Spending.for_envelope(envelope)
```

### Working with Associations

```ruby
spending = Spending.find(1)

# Access the envelope
envelope = spending.envelope
puts envelope.spending_group_name  # e.g., "Groceries"

# Access the monthly budget through the envelope
budget = spending.monthly_budget
puts budget.month_year  # e.g., "2025-12"

# Access the user through the monthly budget
user = spending.user
puts user.display_name
```

## Migration History

- `20251210220000_create_spendings.rb` - Created the `spendings` table
- `20251210220001_migrate_spending_data_to_spendings.rb` - Migrated data from `variable_spending` and `bill_payments` tables
- `20251210220002_drop_variable_spending_and_bill_payments.rb` - Dropped the old `variable_spending` and `bill_payments` tables

## Design Notes

### Consolidation of Tables

The `spendings` table consolidates what were previously two separate tables:
- **Variable Spending**: Multiple spending records per envelope (e.g., multiple grocery trips totaling $500)
- **Bill Payments**: Single payment records per envelope (e.g., one rent payment of $1200)

Both are now represented as `spending` records, simplifying the data model while maintaining the same functionality. The distinction between fixed and variable spending is now handled at the envelope level through the `envelope_template` association, which defines the `group_type`.

### Benefits of Consolidation

1. **Simplified Data Model**: One table instead of two
2. **Easier Queries**: All spending in one place
3. **Consistent Interface**: Same API for all spending types
4. **Flexibility**: Easier to add new spending features

---

**Last Updated**: December 2025

