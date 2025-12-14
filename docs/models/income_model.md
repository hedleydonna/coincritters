# Income Model Documentation

## Overview

The Income model represents income sources for users in the Willow application. Each income source tracks a named income stream (e.g., "Salary", "Freelance Work") with its estimated amount, frequency, and active status.

## Database Table

**Table Name:** `incomes`

### Schema

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | Primary Key | Auto-incrementing unique identifier |
| `user_id` | bigint | NOT NULL | References the user who owns this income (referential integrity enforced at model level) |
| `name` | string | NOT NULL | Name of the income source (e.g., "Salary", "Freelance") |
| `frequency` | string | NOT NULL, Default: "monthly" | How often this income is received |
| `estimated_amount` | decimal(12,2) | NOT NULL, Default: 0.0 | Estimated amount of income |
| `active` | boolean | NOT NULL, Default: true | Whether this income source is currently active |
| `auto_create` | boolean | NOT NULL, Default: false | If `true`, automatically creates income events on the specified day of month |
| `auto_day_of_month` | integer | Nullable, Range: 1-31 | Day of month when automatic income events should be created (required if `auto_create` is `true`) |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Last update timestamp |

### Indexes

- **User ID Index**: Index on `user_id` for fast user lookups
- **User ID + Name Index**: Unique composite index on `[user_id, name]` - prevents duplicate income names per user
- **User ID + Active Index**: Composite index on `[user_id, active]` - optimized for filtering active incomes

### Referential Integrity

**Note:** This codebase does not use database-level foreign key constraints. Referential integrity is enforced at the model level via `belongs_to` validations in Rails 5+.

- **User**: `belongs_to :user` - enforced via model validation. When a user is deleted, all their incomes are deleted via `dependent: :destroy` in the `User` model association.

Cascade deletion is handled via `dependent: :destroy` in model associations, not database-level foreign keys.

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

### Auto Create

- **auto_create**: Boolean flag indicating if income events should be automatically created
  - Default: `false` - User must manually create income events
  - When `true`: System will automatically create income events on the specified day of month
  - **Requires `auto_day_of_month`** when set to `true`

- **auto_day_of_month**: Day of the month when automatic income events should be created
  - Range: 1-31 (day of month)
  - `nil` allowed when `auto_create` is `false`
  - **Required** when `auto_create` is `true`
  - Note: For months with fewer days (e.g., February 30th doesn't exist), the system will use the last day of the month

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

### Auto Create Scope

Returns only incomes that are configured for automatic event creation:

```ruby
user.incomes.auto_create  # Returns only incomes where auto_create: true
```

**Usage:**
- Find incomes that need automatic event generation
- Process scheduled income events
- Display auto-configured incomes in UI

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
- **auto_create**: `false` - Manual event creation by default (user must acknowledge income)
- **auto_day_of_month**: `nil` - No automatic date specified by default

## Usage Examples

### Creating an Income

```ruby
# Basic creation (manual event creation)
income = Income.create!(
  user: current_user,
  name: "Salary",
  frequency: "monthly",
  estimated_amount: 5000.00
)

# With all options (manual event creation)
income = Income.create!(
  user: current_user,
  name: "Freelance Work",
  frequency: "irregular",
  estimated_amount: 1500.50,
  active: true
)

# Auto-create income (automatically creates events on the 1st of each month)
income = Income.create!(
  user: current_user,
  name: "Regular Salary",
  frequency: "monthly",
  estimated_amount: 5000.00,
  auto_create: true,
  auto_day_of_month: 1
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
6. **Auto Create Requirements**: 
   - When `auto_create` is `true`, `auto_day_of_month` must be provided (1-31)
   - When `auto_create` is `false`, `auto_day_of_month` can be `nil`
   - Auto-create is intended for predictable income where `estimated_amount` consistently matches the actual amount received
   - Manual entry (`auto_create: false`) is for variable income where actual amounts may differ from estimates
7. **Auto Create Behavior** (Future Implementation):
   - When `auto_create` is enabled, the system will automatically create `IncomeEvent` records on the specified day of each month
   - The event's `actual_amount` will be set to the income's `estimated_amount` (assuming they match)
   - This reduces manual work for users with consistent, predictable income
   - For variable income, users manually create events and specify the `actual_amount` received

## Auto-Create Feature

### Concept

The auto-create feature allows users to configure income sources that automatically generate `IncomeEvent` records without manual intervention. This addresses two different use cases:

- **Predictable, Consistent Income** (`auto_create: true`): For income where the amount is always the same (e.g., fixed monthly salary). The system automatically creates an income event on the specified day, using the income's `estimated_amount` as the event's `actual_amount`. No manual entry needed.
  
- **Variable Income** (`auto_create: false`): For income where the amount varies month-to-month (e.g., variable paychecks, commissions). The user must manually create income events and enter the `actual_amount` received, which may differ from the `estimated_amount`.

**Key Difference**: 
- Auto-create uses `estimated_amount` directly as `actual_amount` (assumes they match)
- Manual entry allows user to specify the `actual_amount` received (which may differ from `estimated_amount`)

### How It Works

1. **User Configuration**: 
   - For predictable income: User sets `auto_create: true` and specifies `auto_day_of_month` (1-31)
   - For variable income: User sets `auto_create: false` (or leaves it as default `false`)

2. **Automatic Event Generation** (Future Implementation for `auto_create: true`): 
   - System will automatically create `IncomeEvent` records on the specified day of each month
   - Uses the income's `estimated_amount` as the event's `actual_amount` (assuming they match)
   - Uses the income's `name` for the event (or `custom_label` if not linked)
   - Events are attributed to the appropriate month based on `auto_day_of_month`
   - **Assumption**: `estimated_amount` equals the actual amount received (for consistent/predictable income)

3. **Manual Event Creation** (for `auto_create: false`):
   - User manually creates `IncomeEvent` records when income is received
   - User enters the `actual_amount` received (which may differ from `estimated_amount`)
   - Allows flexibility for variable income amounts

4. **Manual Override**: Users can still manually create, edit, or delete auto-generated events if needed

### Use Cases

- **Fixed Monthly Salary**: User always gets paid exactly $5,000 on the 1st → `auto_create: true, auto_day_of_month: 1, estimated_amount: 5000.00`
  - System creates event with `actual_amount: 5000.00` automatically
  
- **Variable Paycheck**: User's paycheck varies (e.g., $4,800-$5,200) due to hours/bonuses → `auto_create: false`
  - User manually creates events each month and enters the actual amount received
  - `estimated_amount` serves as a budget estimate, but `actual_amount` is entered per event
  
- **Consistent Freelance Payment**: User always receives exactly $2,000 on the 15th from a regular client → `auto_create: true, auto_day_of_month: 15`
  
- **Irregular Freelance Income**: User's freelance work varies significantly in amount and timing → `auto_create: false`
  - User manually creates events with varying amounts as income is received

### Future Implementation Notes

- Scheduled job/background task will process auto-create incomes daily
- Check for incomes where `auto_create: true` and `active: true`
- Create events for current month if not already created
- Handle edge cases (end of month, leap years, etc.)
- Allow users to review/approve auto-generated events
- Provide option to disable auto-create for specific months

## Future Enhancements

Potential additions to the Income model:

- **Implementation of Auto-Create**: Background job to automatically generate income events
- **Notes/Description**: Additional details about the income source
- **Start Date / End Date**: Track when income starts and ends
- **Actual Amount**: Track actual income received vs. estimated
- **Categories/Tags**: Categorize income types
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

