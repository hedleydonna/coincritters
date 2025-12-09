# Income Model Documentation

## Overview

The Income model represents income sources for users in the Willow application. Each income source tracks a named income stream (e.g., "Salary", "Freelance Work") with its estimated amount, frequency, and active status.

## Database Table

**Table Name:** `incomes`

### Schema

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | Primary Key | Auto-incrementing unique identifier |
| `user_id` | bigint | NOT NULL, Foreign Key | References the user who owns this income |
| `name` | string | NOT NULL | Name of the income source (e.g., "Salary", "Freelance") |
| `frequency` | string | NOT NULL, Default: "monthly" | How often this income is received |
| `estimated_amount` | decimal(12,2) | NOT NULL, Default: 0.0 | Estimated amount of income |
| `active` | boolean | NOT NULL, Default: true | Whether this income source is currently active |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Last update timestamp |

### Indexes

- **User ID Index**: Index on `user_id` for fast user lookups
- **User ID + Name Index**: Unique composite index on `[user_id, name]` - prevents duplicate income names per user
- **User ID + Active Index**: Composite index on `[user_id, active]` - optimized for filtering active incomes

### Foreign Keys

- **User**: `belongs_to :user` with `on_delete: :cascade` - when a user is deleted, all their incomes are deleted

## Model Location

`app/models/income.rb`

## Associations

### Belongs To

- **User**: Each income belongs to exactly one user
  ```ruby
  income.user  # Returns the User object
  ```

### Has Many (from User)

- **User has_many :incomes**: A user can have multiple income sources
  ```ruby
  user.incomes  # Returns collection of Income objects
  ```

## Validations

### Name

- **Presence**: Name must be present
- **Uniqueness**: Name must be unique per user (different users can have incomes with the same name)
  ```ruby
  # Valid - same name, different users
  user1.incomes.create(name: "Salary", ...)
  user2.incomes.create(name: "Salary", ...)
  
  # Invalid - same name, same user
  user1.incomes.create(name: "Salary", ...)
  user1.incomes.create(name: "Salary", ...)  # Error: name has already been taken
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

## Scopes

### Active Scope

Returns only active income sources for efficient querying:

```ruby
user.incomes.active  # Returns only incomes where active: true
```

**Usage:**
- Filter active income sources
- Calculate current income totals
- Display only relevant incomes to users

## Constants

### FREQUENCIES

Array of valid frequency values:
```ruby
Income::FREQUENCIES
# => ["weekly", "bi_weekly", "monthly", "irregular"]
```

**Usage:**
- Populate frequency dropdowns in forms
- Validate frequency values
- Display frequency options in UI

## Default Values

- **frequency**: `"monthly"` - Most common income frequency
- **estimated_amount**: `0.0` - Safe default until user enters amount
- **active**: `true` - New incomes are active by default

## Usage Examples

### Creating an Income

```ruby
# Basic creation
income = Income.create!(
  user: current_user,
  name: "Salary",
  frequency: "monthly",
  estimated_amount: 5000.00
)

# With all options
income = Income.create!(
  user: current_user,
  name: "Freelance Work",
  frequency: "irregular",
  estimated_amount: 1500.50,
  active: true
)
```

### Querying Incomes

```ruby
# All incomes for a user
user.incomes

# Only active incomes
user.incomes.active

# Find specific income
income = user.incomes.find_by(name: "Salary")

# Check if income exists
user.incomes.exists?(name: "Salary")
```

### Updating Income

```ruby
# Update amount
income.update(estimated_amount: 5500.00)

# Deactivate income
income.update(active: false)

# Change frequency
income.update(frequency: "bi_weekly")
```

### Deleting Income

```ruby
# Delete single income
income.destroy

# Delete all incomes for user (when user is deleted, cascade handles this)
user.destroy  # Automatically deletes all associated incomes
```

## Business Rules

1. **Unique Names Per User**: Users cannot have duplicate income source names (prevents confusion)
2. **Different Users, Same Names**: Multiple users can have incomes with the same name (e.g., both users can have "Salary")
3. **Active Status**: Inactive incomes are retained but hidden from active calculations
4. **Cascade Delete**: Deleting a user automatically deletes all their incomes
5. **Non-Negative Amounts**: Income amounts cannot be negative (for expenses, use a separate model)

## Future Enhancements

Potential additions to the Income model:

- **Notes/Description**: Additional details about the income source
- **Start Date / End Date**: Track when income starts and ends
- **Actual Amount**: Track actual income received vs. estimated
- **Categories/Tags**: Categorize income types
- **Recurring Dates**: Specific dates when irregular income is received
- **Currency**: Support for multiple currencies
- **Income History**: Track income changes over time

## Related Models

- **User**: Parent model - each income belongs to a user
- Future models may include:
  - **Expense**: Track expenses separately from income
  - **Budget**: Create budgets based on income
  - **Transaction**: Record actual income transactions

## Database Constraints

- Foreign key constraint ensures referential integrity
- Unique index prevents duplicate income names per user
- Composite indexes optimize common queries
- Cascade delete maintains data consistency

---

**Last Updated**: December 2025

