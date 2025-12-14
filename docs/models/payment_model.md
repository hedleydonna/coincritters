# Payment Model Documentation

## Overview

The Payment model represents individual payment transactions within an expensein the Willow application. This unified model replaces the previous `variable_payment` and `bill_payments` tables, consolidating all payment records regardless of whether they are fixed bills or variable expenses.

## Database Table

**Table Name:** `payments`

### Schema

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | Primary Key | Auto-incrementing unique identifier |
| `envelope_id` | bigint | NOT NULL, Foreign Key | References the expensethis payment belongs to |
| `amount` | decimal(12,2) | NOT NULL, Default: 0.0 | The amount spent (must be greater than 0) |
| `spent_on` | date | NOT NULL | The date the payment occurred |
| `notes` | text | | Optional notes about the payment |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Last update timestamp |

### Indexes

- **ExpenseID + Spent On Index**: Composite index on `[envelope_id, spent_on]` for fast lookups by expenseand date
- **ExpenseID Index**: Automatically created by `t.references` for foreign key lookups

### Foreign Keys

- `payments.envelope_id` references `expense.id` with `on_delete: :cascade`. If an expenseis deleted, all its payment records are deleted.

## Model Location

`app/models/payment.rb`

## Associations

### Belongs To

- **Expense*: Each payment record belongs to exactly one envelope
  ```ruby
  payment.expense # Returns the Expenseobject
  ```

### Has One Through

- **Monthly Budget**: Each payment record has access to its monthly budget through the envelope
  ```ruby
  payment.monthly_budget  # Returns the MonthlyBudget object
  ```

- **User**: Each payment record has access to its user through the monthly budget
  ```ruby
  payment.user  # Returns the User object
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
Returns payment records ordered by `spent_on` (descending) and `created_at` (descending).

```ruby
Payment.recent  # Most recent payment first
```

### `for_date(date)`
Returns all payment records for a specific date.

```ruby
Payment.for_date(Date.current)  # All payment today
```

### `for_date_range(start_date, end_date)`
Returns all payment records within a date range (inclusive).

```ruby
Payment.for_date_range(Date.current.beginning_of_month, Date.current.end_of_month)  # All payment this month
```

### `for_expenseexpense`
Returns all payment records for a specific expense

```ruby
expense= Expensefind(1)
Payment.for_expenseexpense  # All payment for this envelope
```

## Instance Methods

### `payment_group_name`
Returns the payment group name from the associated expense(delegated to `expensename`).

```ruby
payment.payment_group_name  # e.g., "Groceries", "Rent"
```

### `formatted_amount`
Returns the amount formatted as a currency string using Rails' `number_to_currency` helper. Handles localization and proper currency formatting.

```ruby
payment.formatted_amount  # e.g., "$75.50"
```

### `today?`
Returns `true` if the payment occurred today. Uses `Date.current` for timezone-aware date comparison.

```ruby
payment.today?  # true if spent_on == Date.current
```

### `this_week?`
Returns `true` if the payment occurred this week (Monday through Sunday). Uses `Date.current` for timezone-aware date comparison.

```ruby
payment.this_week?  # true if spent_on is within current week
```

### `this_month?`
Returns `true` if the payment occurred this month. Compares year and month for efficient and accurate month detection.

```ruby
payment.this_month?  # true if spent_on.year == Date.current.year && spent_on.month == Date.current.month
```

### `to_s`
Returns a friendly string representation for debugging and display purposes.

```ruby
payment.to_s  # e.g., "$75.50 on December 15, 2025 – Groceries"
```

## Usage Examples

### Creating a Payment Record

```ruby
expense= Expensefind(1)
payment = Payment.create!(
  expense expense
  amount: 75.50,
  spent_on: Date.current,
  notes: "Weekly grocery shopping"
)
```

### Querying Payment Records

```ruby
# Get recent payment
recent_payment = Payment.recent.limit(10)

# Get payment for a specific date
today_payment = Payment.for_date(Date.current)

# Get payment for this month
monthly_payment = Payment.for_date_range(
  Date.current.beginning_of_month,
  Date.current.end_of_month
)

# Get all payment for a specific envelope
envelope_payment = Payment.for_expenseexpense
```

### Working with Associations

```ruby
payment = Payment.find(1)

# Access the envelope
expense= payment.envelope
puts expensepayment_group_name  # e.g., "Groceries"

# Access the monthly budget through the envelope
budget = payment.monthly_budget
puts budget.month_year  # e.g., "2025-12"

# Access the user through the monthly budget
user = payment.user
puts user.display_name
```

## Migration History

- `20251210220000_create_payments.rb` - Created the `payments` table
- `20251210220001_migrate_payment_data_to_payments.rb` - Migrated data from `variable_payment` and `bill_payments` tables
- `20251210220002_drop_variable_payment_and_bill_payments.rb` - Dropped the old `variable_payment` and `bill_payments` tables

## Design Notes

### Consolidation of Tables

The `payments` table consolidates what were previously two separate tables:
- **Variable Payment**: Multiple payment records per expense(e.g., multiple grocery trips totaling $500)
- **Bill Payments**: Single payment records per expense(e.g., one rent payment of $1200)

Both are now represented as `payment` records, simplifying the data model while maintaining the same functionality. The distinction between fixed and variable payment is now handled at the expenselevel through the `expense_template` association, which defines the `group_type`.

### Benefits of Consolidation

1. **Simplified Data Model**: One table instead of two
2. **Easier Queries**: All payment in one place
3. **Consistent Interface**: Same API for all payment types
4. **Flexibility**: Easier to add new payment features

---

**Last Updated**: December 2025

