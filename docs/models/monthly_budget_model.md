# Monthly Budget Model Documentation

## Overview

The Monthly Budget model represents monthly budget tracking for users in the Willow application. Each monthly budget records the total actual income assigned to a specific month, a flex fund (unassigned money), and an optional bank balance. This allows users to track their financial situation on a month-by-month basis.

## Database Table

**Table Name:** `monthly_budgets`

### Schema

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | Primary Key | Auto-incrementing unique identifier |
| `user_id` | bigint | NOT NULL, Foreign Key | References the user who owns this budget |
| `month_year` | string | NOT NULL | Month and year for this budget (format: YYYY-MM, e.g., "2025-12") |
| `total_actual_income` | decimal(12,2) | NOT NULL, Default: 0.0 | Total actual income assigned to this month from income events |
| `flex_fund` | decimal(12,2) | NOT NULL, Default: 0.0 | Leftover/unassigned money (the user's flex fund) |
| `bank_balance` | decimal(12,2) | Nullable | Optional: manually entered bank balance for verification |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Last update timestamp |

### Indexes

- **User ID + Month Year Index**: Unique composite index on `[user_id, month_year]` - ensures one budget per user per month and provides fast lookup
- **User ID Index**: Index on `user_id` for fast user lookups

### Foreign Keys

- `monthly_budgets.user_id` references `users.id` with `on_delete: :cascade`. If a user is deleted, all their monthly budgets are deleted.

## Model Location

`app/models/monthly_budget.rb`

## Associations

### Belongs To

- **User**: Each monthly budget belongs to exactly one user
  ```ruby
  monthly_budget.user  # Returns the User object
  ```

### Has Many (from User)

- **User has_many :monthly_budgets**: A user can have multiple monthly budgets (one per month)
  ```ruby
  user.monthly_budgets  # Returns collection of MonthlyBudget objects
  ```
  - **Dependent Behavior**: `destroy` - when a user is deleted, all their monthly budgets are deleted

## Validations

### Presence Validations

- `validates :month_year, presence: true`:
  - The `month_year` field must be present.

### Format Validations

- `validates :month_year, format: { with: /\A\d{4}-\d{2}\z/, message: "must be YYYY-MM" }`:
  - `month_year` must match the pattern `YYYY-MM` (e.g., "2025-12").
  - Valid examples: "2025-01", "2025-12", "2024-03"
  - Invalid examples: "2025-1", "25-12", "December 2025"

### Uniqueness Validations

- `validates :month_year, uniqueness: { scope: :user_id }`:
  - A user can only have one budget per month/year combination.
  - Prevents duplicate budgets for the same user and month.

### Numericality Validations

- `validates :total_actual_income, numericality: { greater_than_or_equal_to: 0 }`:
  - `total_actual_income` must be a number greater than or equal to 0.

- `validates :flex_fund, numericality: { greater_than_or_equal_to: 0 }`:
  - `flex_fund` must be a number greater than or equal to 0.

- `validates :bank_balance, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true`:
  - `bank_balance` must be a number greater than or equal to 0 if present.
  - Can be `nil` (optional field).

## Scopes

- `scope :current, -> { find_by(month_year: Time.current.strftime("%Y-%m")) }`:
  - Returns the budget for the current month/year (across all users, returns first match).
  - Useful for finding the current month's budget.

- `scope :for_month, ->(year_month) { find_by(month_year: year_month) }`:
  - Returns a single budget for a specific month/year (across all users, returns first match).
  - Similar to `current` but for any specified month.

- `scope :by_month, ->(month_year) { where(month_year: month_year) }`:
  - Returns all budgets for a specific month/year (across all users).
  - Returns a collection, unlike `for_month` which returns a single record.

- `scope :for_user, ->(user) { where(user: user) }`:
  - Returns all budgets for a specific user.

## Instance Methods

### Display Methods

- `name` - Returns a human-readable name for the budget (e.g., "December 2025")
  ```ruby
  budget.name  # => "December 2025"
  ```

- `month_year_with_user` - Returns a string combining month_year and user display name for dropdowns
  ```ruby
  budget.month_year_with_user  # => "2025-12 - John Doe"
  ```

### Calculation Methods

- `total_allotted` - Returns the sum of `allotted_amount` from all associated expense
  ```ruby
  budget.total_allotted  # => 2000.00
  ```

- `total_spent` - Returns the sum of `spent_amount` (calculated from payments) across all expense
  ```ruby
  budget.total_spent  # => 1500.00
  ```

- `remaining_to_assign` - Returns the difference between `total_actual_income` and `total_allotted`
  ```ruby
  budget.remaining_to_assign  # => 3000.00 (if total_actual_income is 5000.00 and total_allotted is 2000.00)
  ```
  - This represents how much income is left to assign to expense.
  - Can be negative if more has been allotted than actual income.

- `unassigned` - Returns the remaining amount, but never negative (clamped to 0)
  ```ruby
  budget.unassigned  # => 3000.00 (same as remaining_to_assign if positive, otherwise 0)
  ```
  - This is the "safe" version that never goes below zero.
  - Represents unassigned money that can be swept to savings or next month.

- `bank_difference` - Returns the difference between `bank_balance` and calculated balance, or `nil` if `bank_balance` is not set
  ```ruby
  budget.bank_difference  # => 100.00 (if bank_balance is 3100.00 and calculated is 3000.00)
  ```

- `bank_match?` - Returns `true` if `bank_balance` matches calculated balance within $50 tolerance, or `true` if `bank_balance` is not set
  ```ruby
  budget.bank_match?  # => true or false
  ```

### ExpenseManagement Methods

- `auto_create_expense` - Automatically creates expense for all payment categories with `auto_create: true` that don't already have an expensein this budget
  ```ruby
  budget.auto_create_expense
  # Creates expense for each payment category with auto_create: true
  # Uses category.default_amount for the expenses allotted_amount
  # Skips categories that already have an expensein this budget
  ```

## Business Rules

1. **One Budget Per User Per Month**: Each user can only have one budget for each month/year combination. The unique index on `[user_id, month_year]` enforces this at the database level.

2. **Non-Negative Amounts**: All monetary fields (`total_actual_income`, `flex_fund`, `bank_balance`) cannot be negative (zero is allowed).

3. **Optional Bank Balance**: The `bank_balance` field is optional and can be `nil`. This allows users to manually enter their bank balance for verification purposes.

4. **Default Values**: 
   - New monthly budgets default to `total_actual_income: 0.0` if not specified
   - New monthly budgets default to `flex_fund: 0.0` if not specified

5. **Cascade Deletion**: Deleting a user will delete all their monthly budgets.

## Usage Examples

### Creating a Monthly Budget

```ruby
user = User.first

budget = user.monthly_budgets.create(
  month_year: "2025-12",
  total_actual_income: 5000.00,
  flex_fund: 500.00,
  bank_balance: 3000.00
)
# => #<MonthlyBudget id: 1, user_id: 1, month_year: "2025-12", ...>
```

### Creating with Default Values

```ruby
budget = user.monthly_budgets.create(
  month_year: "2026-01"
)
# => #<MonthlyBudget ... total_actual_income: 0.0, flex_fund: 0.0, bank_balance: nil>
```

### Retrieving Budgets by Month

```ruby
december_budgets = MonthlyBudget.by_month("2025-12")
# => #<ActiveRecord::Relation [#<MonthlyBudget ... month_year: "2025-12">, ...]>
```

### Retrieving Budgets for a User

```ruby
user = User.first
user_budgets = MonthlyBudget.for_user(user)
# => #<ActiveRecord::Relation [#<MonthlyBudget ... user_id: 1>, ...]>
```

### Finding a User's Budget for a Specific Month

```ruby
user = User.first
december_budget = user.monthly_budgets.find_by(month_year: "2025-12")
# => #<MonthlyBudget ... month_year: "2025-12">
```

### Auto-Creating Expense

```ruby
budget = MonthlyBudget.create!(
  user: user,
  month_year: "2026-01",
  total_actual_income: 5000.00
)

# Auto-create expense for payment categories with auto_create: true
budget.auto_create_expense
# => Creates expense for categories like "Groceries", "Rent", "Emergency Fund"
# Each expensegets the category's default_amount as its allotted_amount
```

### Updating a Monthly Budget

```ruby
budget = MonthlyBudget.find(1)
budget.update(
  total_actual_income: 5500.00,
  flex_fund: 600.00
)
# => true
```

### Handling Validation Errors

```ruby
user = User.first

# Invalid month_year format
invalid_budget = user.monthly_budgets.create(
  month_year: "December 2025",
  total_actual_income: 5000.00
)
# => #<MonthlyBudget ... errors: {:month_year=>["must be YYYY-MM"]}>

# Duplicate month for same user
duplicate_budget = user.monthly_budgets.create(
  month_year: user.monthly_budgets.first.month_year,
  total_actual_income: 6000.00
)
# => #<MonthlyBudget ... errors: {:month_year=>["has already been taken"]}>

# Negative amount
invalid_amount = user.monthly_budgets.create(
  month_year: "2026-01",
  total_actual_income: -100.00
)
# => #<MonthlyBudget ... errors: {:total_actual_income=>["must be greater than or equal to 0"]}>
```

## Key Concepts

### Total Actual Income

The `total_actual_income` field represents the total amount of actual income that has been assigned to this month from income events. This is typically calculated from `IncomeEvent` records where `assigned_month_year` matches the budget's `month_year`.

### Flex Fund

The `flex_fund` represents leftover or unassigned money that the user has available for discretionary payment. This is money that hasn't been allocated to specific categories or expenses.

### Bank Balance

The optional `bank_balance` field allows users to manually enter their actual bank balance for the month. This can be used for verification and reconciliation purposes, providing a "forgiving" check against calculated balances.

### Month/Year Format

The `month_year` field uses the format `YYYY-MM` (e.g., "2025-12" for December 2025). This format:
- Is easy to sort chronologically as a string
- Allows for efficient database queries
- Is human-readable
- Matches the format used in `IncomeEvent.month_year` and `IncomeEvent.assigned_month_year`

## Relationship to Income Events

Monthly budgets are related to income events through the `assigned_month_year` field:
- An `IncomeEvent` can have an `assigned_month_year` that matches a `MonthlyBudget.month_year`
- The `total_actual_income` in a monthly budget should ideally match the sum of `actual_amount` from income events assigned to that month

## Admin Dashboard

Monthly budgets can be managed through the admin dashboard:
- **View All**: `/admin/monthly_budgets`
- **View Details**: `/admin/monthly_budgets/:id`
- **Edit**: `/admin/monthly_budgets/:id/edit`
- **Create**: `/admin/monthly_budgets/new`

The admin dashboard displays:
- Total count of monthly budgets
- Recent monthly budgets
- Ability to create, edit, and delete budgets

## Migration History

- `20251210003311_create_monthly_budgets.rb` - Initial monthly_budgets table creation

## Future Enhancements

- **Automatic Calculation**: Automatically calculate `total_actual_income` from associated income events
- **Budget Categories**: Add support for budget categories/expense within a monthly budget
- **Payment Tracking**: Track actual payment against budgeted amounts
- **Carryover**: Automatically carry over unused flex fund to next month
- **Reports**: Generate monthly/quarterly/annual budget reports
- **Forecasting**: Predict future budgets based on historical data
- **Notifications**: Alert users when budgets are created or updated
- **Reconciliation**: Tools to reconcile bank balance with calculated balances
- **Multi-currency**: Support for different currencies
- **Budget Templates**: Pre-defined budget templates based on income level or lifestyle

---

**Last Updated**: December 2025

