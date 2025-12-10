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
| `spending_group_name` | string | NOT NULL | User-typed label for this spending category (e.g., "Groceries", "Rent") |
| `group_type` | integer | NOT NULL, Default: 1 | Type of spending: 0 = fixed, 1 = variable |
| `is_savings` | boolean | NOT NULL, Default: false | Whether this is a savings pot (emergency fund, vacation, etc.) |
| `allotted_amount` | decimal(12,2) | NOT NULL, Default: 0.0 | How much the user assigned to this envelope this month |
| `spent_amount` | decimal(12,2) | NOT NULL, Default: 0.0 | How much has been spent from this envelope (updated live) |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Last update timestamp |

### Indexes

- **Monthly Budget ID + Spending Group Name Index**: Unique composite index on `[monthly_budget_id, spending_group_name]` - ensures one envelope per name per budget
- **Monthly Budget ID Index**: Index on `monthly_budget_id` for fast budget lookups

### Foreign Keys

- `envelopes.monthly_budget_id` references `monthly_budgets.id` with `on_delete: :cascade`. If a monthly budget is deleted, all its envelopes are deleted.

## Model Location

`app/models/envelope.rb`

## Associations

### Belongs To

- **Monthly Budget**: Each envelope belongs to exactly one monthly budget
  ```ruby
  envelope.monthly_budget  # Returns the MonthlyBudget object
  ```

### Has Many (from Monthly Budget)

- **MonthlyBudget has_many :envelopes**: A monthly budget can have multiple envelopes
  ```ruby
  monthly_budget.envelopes  # Returns collection of Envelope objects
  ```
  - **Dependent Behavior**: `destroy` - when a monthly budget is deleted, all its envelopes are deleted

## Validations

### Presence Validations

- `validates :spending_group_name, presence: true`:
  - The `spending_group_name` field must be present.

### Uniqueness Validations

- `validates :spending_group_name, uniqueness: { scope: :monthly_budget_id, message: "already exists for this budget" }`:
  - A monthly budget can only have one envelope with a given `spending_group_name`.
  - Prevents duplicate envelope names within the same budget.

### Inclusion Validations

- `validates :group_type, inclusion: { in: GROUP_TYPES.values, message: "must be 0 (fixed) or 1 (variable)" }`:
  - `group_type` must be either 0 (fixed) or 1 (variable).

### Numericality Validations

- `validates :allotted_amount, numericality: { greater_than_or_equal_to: 0 }`:
  - `allotted_amount` must be a number greater than or equal to 0.

- `validates :spent_amount, numericality: { greater_than_or_equal_to: 0 }`:
  - `spent_amount` must be a number greater than or equal to 0.

## Constants

- `GROUP_TYPES = { fixed: 0, variable: 1 }.freeze`:
  - Defines the allowed values for `group_type`:
    - `0` = Fixed expenses (recurring bills like rent, Netflix subscriptions)
    - `1` = Variable expenses (flexible spending like food, entertainment)

## Scopes

- `scope :fixed, -> { where(group_type: GROUP_TYPES[:fixed]) }`:
  - Returns only envelopes with `group_type = 0` (fixed expenses).

- `scope :variable, -> { where(group_type: GROUP_TYPES[:variable]) }`:
  - Returns only envelopes with `group_type = 1` (variable expenses).

- `scope :savings, -> { where(is_savings: true) }`:
  - Returns only envelopes marked as savings pots.

- `scope :non_savings, -> { where(is_savings: false) }`:
  - Returns only envelopes that are not savings pots.

## Instance Methods

### Type Checking

- `fixed?`: Returns `true` if `group_type == 0` (fixed expense).
- `variable?`: Returns `true` if `group_type == 1` (variable expense).

### Financial Calculations

- `remaining`: Returns `allotted_amount - spent_amount` (can be negative if over budget).
- `available`: Returns the available amount (never negative). If `remaining` is negative, returns 0.
- `over_budget?`: Returns `true` if `spent_amount > allotted_amount`.
- `spent_percentage`: Returns the percentage of allotted amount that has been spent (capped at 100%).

## Business Rules

1. **One Envelope Per Name Per Budget**: Each monthly budget can only have one envelope with a given `spending_group_name`. Different budgets can have envelopes with the same name.

2. **Group Types**: 
   - **Fixed (0)**: Recurring, predictable expenses (rent, subscriptions, insurance)
   - **Variable (1)**: Flexible, variable expenses (groceries, entertainment, dining out)

3. **Savings Envelopes**: Envelopes can be marked as savings pots (`is_savings: true`) for goals like emergency funds, vacations, or major purchases.

4. **Non-Negative Amounts**: Both `allotted_amount` and `spent_amount` cannot be negative (zero is allowed).

5. **Default Values**: 
   - New envelopes default to `group_type: 1` (variable)
   - New envelopes default to `is_savings: false`
   - New envelopes default to `allotted_amount: 0.0`
   - New envelopes default to `spent_amount: 0.0`

6. **Cascade Deletion**: Deleting a monthly budget will delete all its associated envelopes.

## Usage Examples

### Creating an Envelope

```ruby
budget = MonthlyBudget.first

envelope = budget.envelopes.create(
  spending_group_name: "Groceries",
  group_type: 1,  # variable
  is_savings: false,
  allotted_amount: 500.00,
  spent_amount: 320.50
)
# => #<Envelope id: 1, monthly_budget_id: 1, spending_group_name: "Groceries", ...>
```

### Creating a Fixed Expense Envelope

```ruby
budget = MonthlyBudget.first

rent_envelope = budget.envelopes.create(
  spending_group_name: "Rent",
  group_type: 0,  # fixed
  allotted_amount: 1200.00,
  spent_amount: 1200.00
)
```

### Creating a Savings Envelope

```ruby
budget = MonthlyBudget.first

emergency_fund = budget.envelopes.create(
  spending_group_name: "Emergency Fund",
  group_type: 0,  # fixed
  is_savings: true,
  allotted_amount: 300.00,
  spent_amount: 0.00
)
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
```

### Calculating Remaining and Available Amounts

```ruby
envelope = Envelope.first
# => #<Envelope ... allotted_amount: 500.00, spent_amount: 320.50>

envelope.remaining
# => #<BigDecimal "179.5">

envelope.available
# => #<BigDecimal "179.5">

envelope.over_budget?
# => false

# Over budget example
over_budget_envelope = Envelope.new(
  allotted_amount: 100.00,
  spent_amount: 150.00
)
over_budget_envelope.remaining
# => #<BigDecimal "-50.0">

over_budget_envelope.available
# => #<BigDecimal "0.0">

over_budget_envelope.over_budget?
# => true
```

### Calculating Spent Percentage

```ruby
envelope = Envelope.first
# => #<Envelope ... allotted_amount: 500.00, spent_amount: 320.50>

envelope.spent_percentage
# => 64.1

fully_spent = Envelope.new(
  allotted_amount: 200.00,
  spent_amount: 200.00
)
fully_spent.spent_percentage
# => 100.0
```

### Handling Validation Errors

```ruby
budget = MonthlyBudget.first

# Duplicate name in same budget
duplicate = budget.envelopes.create(
  spending_group_name: budget.envelopes.first.spending_group_name,
  group_type: 1
)
# => #<Envelope ... errors: {:spending_group_name=>["already exists for this budget"]}>

# Invalid group_type
invalid_type = budget.envelopes.create(
  spending_group_name: "Test",
  group_type: 999
)
# => #<Envelope ... errors: {:group_type=>["must be 0 (fixed) or 1 (variable)"]}>

# Negative amounts
negative_amount = budget.envelopes.create(
  spending_group_name: "Test",
  group_type: 1,
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

