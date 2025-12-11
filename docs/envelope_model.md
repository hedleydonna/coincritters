# Envelope Model Documentation

## Overview

The Envelope model represents spending categories within a monthly budget in the Willow application. Envelopes are a budgeting method where money is allocated to different spending categories (like "Groceries", "Rent", "Entertainment"). Each envelope tracks how much was allotted for the month and how much has actually been spent.

## Database Table

**Table Name:** `envelopes`

### Schema

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | Primary Key | Auto-incrementing unique identifier |
| `monthly_budget_id` | bigint | NOT NULL, Foreign Key | References the monthly budget this envelope belongs to |
| `spending_category_id` | bigint | NOT NULL, Foreign Key | References the spending category this envelope belongs to |
| `allotted_amount` | decimal(12,2) | NOT NULL, Default: 0.0 | How much the user assigned to this envelope this month |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Last update timestamp |

### Indexes

- **Monthly Budget ID + Spending Category ID Index**: Unique composite index on `[monthly_budget_id, spending_category_id]` - ensures one envelope per spending category per budget
- **Monthly Budget ID Index**: Index on `monthly_budget_id` for fast budget lookups
- **Spending Category ID Index**: Index on `spending_category_id` for fast category lookups

### Foreign Keys

- `envelopes.monthly_budget_id` references `monthly_budgets.id` with `on_delete: :cascade`. If a monthly budget is deleted, all its envelopes are deleted.
- `envelopes.spending_category_id` references `spending_categories.id` with `on_delete: :cascade`. If a spending category is deleted, all its envelopes are deleted.

## Model Location

`app/models/envelope.rb`

## Associations

### Belongs To

- **Monthly Budget**: Each envelope belongs to exactly one monthly budget
  ```ruby
  envelope.monthly_budget  # Returns the MonthlyBudget object
  ```

- **Spending Category**: Each envelope belongs to exactly one spending category
  ```ruby
  envelope.spending_category  # Returns the SpendingCategory object
  ```

### Has Many

- **Spendings**: Each envelope can have many spending records
  ```ruby
  envelope.spendings  # Returns collection of Spending objects
  ```
  - **Dependent Behavior**: `destroy` - when an envelope is deleted, all its spending records are deleted

### Has Many (from Monthly Budget)

- **MonthlyBudget has_many :envelopes**: A monthly budget can have multiple envelopes
  ```ruby
  monthly_budget.envelopes  # Returns collection of Envelope objects
  ```
  - **Dependent Behavior**: `destroy` - when a monthly budget is deleted, all its envelopes are deleted

## Validations

### Numericality Validations

- `validates :allotted_amount, numericality: { greater_than_or_equal_to: 0 }`:
  - `allotted_amount` must be a number greater than or equal to 0.

### Uniqueness Validations

- `validates :spending_category_id, uniqueness: { scope: :monthly_budget_id }`:
  - A monthly budget can only have one envelope for each spending category.
  - Prevents duplicate spending categories within the same budget.

### Database Constraints

- **Unique Constraint**: The database enforces uniqueness on `[monthly_budget_id, spending_category_id]` - a monthly budget can only have one envelope per spending category.

## Callbacks

- `before_validation :set_default_allotted_amount, on: :create`:
  - Automatically sets `allotted_amount` from the spending category's `default_amount` when creating a new envelope.
  - Only applies if `allotted_amount` is not explicitly set.
  - If category's `default_amount` is `nil`, defaults to `0.0`.

## Scopes

- `scope :fixed`: Returns only envelopes whose spending category has `group_type = 0` (fixed expenses).
- `scope :variable`: Returns only envelopes whose spending category has `group_type = 1` (variable expenses).
- `scope :savings`: Returns only envelopes whose spending category has `is_savings = true`.
- `scope :non_savings`: Returns only envelopes whose spending category has `is_savings = false`.
- `scope :over_budget`: Returns only envelopes where the sum of spending amounts exceeds the allotted amount. Uses a SQL subquery for efficient database-level filtering.

## Instance Methods

### Accessing Category Properties

- `name`: Returns the name from the associated spending category (delegated to `spending_category.name`).
- `display_name`: Returns the display name from the associated spending category (delegated to `spending_category.display_name`).
- `spending_group_name`: Alias for `name` (for backward compatibility).
- `group_type`: Returns the group type from the associated spending category (delegated).
- `group_type_text`: Returns the text description of the group type (delegated to spending category).

### Type Checking

- `fixed?`: Returns `true` if the spending category's `group_type == 0` (fixed expense).
- `variable?`: Returns `true` if the spending category's `group_type == 1` (variable expense).
- `savings?`: Returns `true` if the spending category's `is_savings == true`.
- `is_savings?`: Alias for `savings?` (for backward compatibility).

### Financial Calculations

- `spent_amount`: **Calculated method** - Returns the sum of all spending records for this envelope (`spendings.sum(:amount)`).
- `remaining`: Returns `allotted_amount - spent_amount` (can be negative if over budget).
- `available`: Returns the available amount (never negative). If `remaining` is negative, returns 0.
- `over_budget?`: Returns `true` if `spent_amount > allotted_amount`.
- `under_budget?`: Returns `true` if `spent_amount < allotted_amount`.
- `paid?`: Returns `true` for fixed bills when `spent_amount >= allotted_amount`. Always returns `false` for variable expenses.
- `spent_percentage`: Returns the percentage of allotted amount that has been spent (capped at 100%, returns decimal). Safely handles zero and negative allotted amounts by returning 0.
- `percent_used`: Returns the percentage of allotted amount that has been spent (integer, rounded, not capped).

### Display Helpers

- `display_name_with_budget`: Returns a string combining the envelope name and budget month/year (e.g., "Groceries (2025-12)").
- `to_s`: Returns a friendly string representation for debugging/selects (e.g., "Groceries (December 2025)").

## Business Rules

1. **One Envelope Per Spending Category Per Budget**: Each monthly budget can only have one envelope for a given spending category. Different budgets can use the same spending category.

2. **Name and Type from Category**: The envelope's name, group type (fixed/variable), and savings status all come from the associated spending category, not stored directly on the envelope.

3. **Spent Amount is Calculated**: The `spent_amount` is calculated from the sum of all related spending records. It is not stored in the database and updates automatically as spending records are added or removed.

4. **Non-Negative Allotted Amount**: `allotted_amount` cannot be negative (zero is allowed).

5. **Default Values**: 
   - New envelopes automatically get `allotted_amount` from the spending category's `default_amount` (if set).
   - If category's `default_amount` is `nil` or not set, defaults to `0.0`.
   - Explicitly set `allotted_amount` values are not overridden by the default.
   - `spent_amount` always starts at 0.0 (when there are no spending records)

6. **Cascade Deletion**: 
   - Deleting a monthly budget will delete all its associated envelopes.
   - Deleting a spending category will delete all associated envelopes.
   - Deleting an envelope will delete all its associated spending records.

## Usage Examples

### Creating an Envelope

```ruby
budget = MonthlyBudget.first
groceries_category = budget.user.spending_categories.find_or_create_by!(name: "Groceries") do |sc|
  sc.group_type = :variable
  sc.is_savings = false
  sc.default_amount = 500.00
end

# Create envelope - allotted_amount will be auto-filled from category default_amount
envelope = budget.envelopes.create(
  spending_category: groceries_category
)
# => #<Envelope id: 1, monthly_budget_id: 1, spending_category_id: 1, allotted_amount: 500.00, ...>

# Or explicitly set the amount (overrides default)
envelope = budget.envelopes.create(
  spending_category: groceries_category,
  allotted_amount: 600.00
)
# => #<Envelope ... allotted_amount: 600.00>

# Access the name (from spending category)
envelope.name  # => "Groceries"
envelope.display_name  # => "Groceries" (or "Groceries (Savings)" if savings)
envelope.spending_group_name  # => "Groceries" (alias for name)
```

### Creating a Fixed Expense Envelope

```ruby
budget = MonthlyBudget.first
rent_category = budget.user.spending_categories.find_or_create_by!(name: "Rent") do |sc|
  sc.group_type = :fixed
  sc.is_savings = false
end

rent_envelope = budget.envelopes.create(
  spending_category: rent_category,
  allotted_amount: 1200.00
)

# Add spending records
rent_envelope.spendings.create!(amount: 1200.00, spent_on: Date.today)
rent_envelope.spent_amount  # => 1200.00 (calculated)
```

### Creating a Savings Envelope

```ruby
budget = MonthlyBudget.first
emergency_category = budget.user.spending_categories.find_or_create_by!(name: "Emergency Fund") do |sc|
  sc.group_type = :fixed
  sc.is_savings = true
end

emergency_fund = budget.envelopes.create(
  spending_category: emergency_category,
  allotted_amount: 300.00
)
# spent_amount starts at 0.0 (no spending records yet)
emergency_fund.spent_amount  # => 0.0
```

### Retrieving Envelopes by Type

```ruby
budget = MonthlyBudget.first

fixed_envelopes = budget.envelopes.fixed
# => #<ActiveRecord::Relation [#<Envelope ... group_type: 0>, ...]>

variable_envelopes = budget.envelopes.variable
# => #<ActiveRecord::Relation [#<Envelope ... group_type: 1>, ...]>

savings_envelopes = budget.envelopes.savings
# => #<ActiveRecord::Relation [#<Envelope ... is_savings: true>, ...]>

# Find envelopes that are over budget (efficient database query)
over_budget_envelopes = budget.envelopes.over_budget
# => #<ActiveRecord::Relation [#<Envelope ... spent > allotted>, ...]>
```

### Calculating Remaining and Available Amounts

```ruby
envelope = Envelope.first
# => #<Envelope ... allotted_amount: 500.00>

# Create some spending records
envelope.spendings.create!(amount: 100.00, spent_on: Date.today)
envelope.spendings.create!(amount: 50.00, spent_on: Date.today)
envelope.spent_amount  # => 150.00 (calculated from spendings)

envelope.remaining  # => 350.00 (allotted_amount - spent_amount)
envelope.available  # => 350.00
envelope.over_budget?  # => false

# Over budget example
over_budget_envelope = Envelope.create!(
  monthly_budget: budget,
  spending_category: category,
  allotted_amount: 100.00
)
over_budget_envelope.spendings.create!(amount: 150.00, spent_on: Date.today)
over_budget_envelope.spent_amount  # => 150.00

over_budget_envelope.remaining  # => -50.00
over_budget_envelope.available  # => 0.00 (never negative)
over_budget_envelope.over_budget?  # => true
```

### Calculating Spent Percentage

```ruby
envelope = Envelope.first
envelope.allotted_amount  # => 500.00
envelope.spendings.create!(amount: 320.50, spent_on: Date.today)
envelope.spent_amount  # => 320.50

envelope.spent_percentage  # => 64.1 (decimal, capped at 100%)
envelope.percent_used  # => 64 (integer, rounded, not capped)

# Fully spent
envelope.spendings.create!(amount: 179.50, spent_on: Date.today)
envelope.spent_amount  # => 500.00
envelope.spent_percentage  # => 100.0 (capped at 100%)
envelope.percent_used  # => 100 (integer)
```

### Checking if Fixed Bill is Paid

```ruby
budget = MonthlyBudget.first
rent_category = budget.user.spending_categories.find_or_create_by!(name: "Rent") do |sc|
  sc.group_type = :fixed
  sc.default_amount = 1200.00
end

rent_envelope = budget.envelopes.create(spending_category: rent_category)
rent_envelope.allotted_amount  # => 1200.00 (from category default)

# Not paid yet
rent_envelope.paid?  # => false

# Add spending equal to allotted amount
rent_envelope.spendings.create!(amount: 1200.00, spent_on: Date.today)
rent_envelope.paid?  # => true

# Variable expenses are never "paid"
groceries_category = budget.user.spending_categories.find_or_create_by!(name: "Groceries") do |sc|
  sc.group_type = :variable
end
groceries_envelope = budget.envelopes.create(
  spending_category: groceries_category,
  allotted_amount: 500.00
)
groceries_envelope.spendings.create!(amount: 500.00, spent_on: Date.today)
groceries_envelope.paid?  # => false (only fixed bills can be "paid")
```

### Display Methods

```ruby
envelope = Envelope.first

# String representation for debugging/selects
envelope.to_s  # => "Groceries (December 2025)"

# Display name with budget month
envelope.display_name_with_budget  # => "Groceries (2025-12)"
```

### Handling Validation Errors

```ruby
budget = MonthlyBudget.first
category = budget.user.spending_categories.first

# Duplicate spending category in same budget
duplicate = budget.envelopes.create(
  spending_category: category  # if already exists
)
# => #<Envelope ... errors: {:spending_category_id=>["has already been taken"]}>

# Negative allotted amount
negative_amount = budget.envelopes.create(
  spending_category: category,
  allotted_amount: -100.00
)
# => #<Envelope ... errors: {:allotted_amount=>["must be greater than or equal to 0"]}>
```

## Key Concepts

### Fixed vs Variable Expenses

- **Fixed (0)**: Expenses that are consistent month-to-month and not easily changed:
  - Rent/mortgage
  - Subscription services (Netflix, Spotify)
  - Insurance premiums
  - Loan payments
  
- **Variable (1)**: Expenses that fluctuate and can be adjusted:
  - Groceries
  - Dining out
  - Entertainment
  - Gas/transportation
  - Clothing

### Savings Envelopes

Savings envelopes (`is_savings: true`) represent money set aside for future goals rather than current spending:
- Emergency fund
- Vacation savings
- Down payment fund
- Major purchase savings
- Investment savings

These envelopes typically have `spent_amount: 0.00` as the money is being accumulated, not spent.

### Envelope Budgeting Method

The envelope method is a budgeting technique where income is divided into categories (envelopes) and spending is tracked against each category. This helps users:
- Stay within budget for each category
- See exactly where money is going
- Make informed decisions about discretionary spending
- Build savings systematically

### Relationship to Monthly Budget

- Each envelope belongs to a specific monthly budget
- The sum of `allotted_amount` across all envelopes should typically match or be less than `monthly_budget.total_actual_income`
- The `monthly_budget.remaining` method calculates `total_actual_income - total_allotted` to show unassigned money

## Admin Dashboard

Envelopes can be managed through the admin dashboard:
- **View All**: `/admin/envelopes`
- **View Details**: `/admin/envelopes/:id`
- **Edit**: `/admin/envelopes/:id/edit`
- **Create**: `/admin/envelopes/new`

The admin dashboard displays:
- Total count of envelopes
- Recent envelopes
- Ability to create, edit, and delete envelopes

## Migration History

- `20251210005820_create_envelopes.rb` - Initial envelopes table creation

## Future Enhancements

- **Automatic Spending Tracking**: Integrate with transaction import to automatically update `spent_amount`
- **Recurring Envelopes**: Copy envelope structure from previous month
- **Envelope Templates**: Pre-defined envelope sets for common budgeting styles
- **Spending Alerts**: Notify users when approaching or exceeding envelope limits
- **Envelope Goals**: Track progress toward savings goals
- **Color Coding**: Visual indicators for envelope types and status
- **Spending Trends**: Show spending patterns over time for each envelope
- **Envelope Rollover**: Carry over unspent amounts to next month (optional)
- **Budget Recommendations**: Suggest envelope allocations based on income

---

**Last Updated**: December 2025

