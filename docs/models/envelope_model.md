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
| `envelope_template_id` | bigint | NOT NULL, Foreign Key | References the envelope template this envelope is based on |
| `allotted_amount` | decimal(12,2) | NOT NULL, Default: 0.0 | How much the user assigned to this envelope this month |
| `name` | string | Nullable | Override field: Custom name for this envelope (uses template name if null) |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Last update timestamp |

### Indexes

- **Monthly Budget ID + Envelope Template ID Index**: Unique composite index on `[monthly_budget_id, envelope_template_id]` - ensures one envelope per template per budget (unless name override is used)
- **Monthly Budget ID Index**: Index on `monthly_budget_id` for fast budget lookups
- **Envelope Template ID Index**: Index on `envelope_template_id` for fast template lookups
- **Monthly Budget ID + Name Index**: Composite index on `[monthly_budget_id, name]` - for name override lookups

### Foreign Keys

- `envelopes.monthly_budget_id` references `monthly_budgets.id` with `on_delete: :cascade`. If a monthly budget is deleted, all its envelopes are deleted.
- `envelopes.envelope_template_id` references `envelope_templates.id` with `on_delete: :cascade`. If an envelope template is deleted, all its envelopes are deleted.

## Model Location

`app/models/envelope.rb`

## Associations

### Belongs To

- **Monthly Budget**: Each envelope belongs to exactly one monthly budget
  ```ruby
  envelope.monthly_budget  # Returns the MonthlyBudget object
  ```

- **Envelope Template**: Each envelope belongs to exactly one envelope template
  ```ruby
  envelope.envelope_template  # Returns the EnvelopeTemplate object
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

- `validates :envelope_template_id, uniqueness: { scope: :monthly_budget_id }`:
  - A monthly budget can only have one envelope for each envelope template (unless name override is used).
  - Prevents duplicate templates within the same budget.
- `validates :name, uniqueness: { scope: :monthly_budget_id }` (if name override is used):
  - If using a name override, the name must be unique within the monthly budget.

### Database Constraints

- **Unique Constraint**: The database enforces uniqueness on `[monthly_budget_id, envelope_template_id]` - a monthly budget can only have one envelope per template (unless name override is used).

## Callbacks

- `before_validation :set_default_allotted_amount, on: :create`:
  - Automatically sets `allotted_amount` from the envelope template's `default_amount` when creating a new envelope.
  - Only applies if `allotted_amount` is not explicitly set.
  - If template's `default_amount` is `nil`, defaults to `0.0`.

## Scopes

- `scope :fixed`: Returns only envelopes that are fixed (delegates to template).
- `scope :variable`: Returns only envelopes that are variable (delegates to template).
- `scope :savings`: Returns only envelopes that are savings (delegates to template).
- `scope :non_savings`: Returns only envelopes that are not savings (delegates to template).
- `scope :over_budget`: Returns only envelopes where the sum of spending amounts exceeds the allotted amount. Uses a SQL subquery for efficient database-level filtering.

## Instance Methods

### Accessing Template Properties

- `name`: Returns the override name if present, otherwise returns the template name.
- `display_name`: Returns a friendly display name (includes "(Savings)" if applicable).
- `spending_group_name`: Alias for `name` (for backward compatibility).
- `group_type`: Returns the template's group_type (always from template).
- `group_type_text`: Returns the text description of the group type ("Fixed bill" or "Variable spending").

### Type Checking

- `fixed?`: Returns `true` if the envelope is fixed (always from template).
- `variable?`: Returns `true` if the envelope is variable (always from template).
- `savings?`: Returns `true` if the envelope is a savings envelope (always from template).
- `is_savings?`: Alias for `savings?` (for backward compatibility).
- `has_overrides?`: Returns `true` if the envelope has a name override.
- `name_overridden?`: Returns `true` if the name is overridden.

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

2. **Name, Type, and Savings Status from Template**: The envelope's group type (fixed/variable) and savings status always come from the associated envelope template. The envelope's name can optionally be overridden on a per-envelope basis. If the name override is not set, the template's name is used.

3. **Spent Amount is Calculated**: The `spent_amount` is calculated from the sum of all related spending records. It is not stored in the database and updates automatically as spending records are added or removed.

4. **Non-Negative Allotted Amount**: `allotted_amount` cannot be negative (zero is allowed).

5. **Default Values**: 
   - New envelopes automatically get `allotted_amount` from the envelope template's `default_amount` (if set).
   - If template's `default_amount` is `nil` or not set, defaults to `0.0`.
   - Explicitly set `allotted_amount` values are not overridden by the default.
   - `spent_amount` always starts at 0.0 (when there are no spending records)
   - The `name` override field defaults to `nil` and uses the template name when not set.
   - `group_type` and `is_savings` always come from the template (not overrideable).

6. **Cascade Deletion**: 
   - Deleting a monthly budget will delete all its associated envelopes.
   - Deleting an envelope template will delete all associated envelopes.
   - Deleting an envelope will delete all its associated spending records.

## Usage Examples

### Creating an Envelope

```ruby
budget = MonthlyBudget.first
groceries_template = budget.user.envelope_templates.find_or_create_by!(name: "Groceries") do |et|
  et.group_type = :variable
  et.is_savings = false
  et.default_amount = 500.00
end

# Create envelope - allotted_amount will be auto-filled from template default_amount
envelope = budget.envelopes.create(
  envelope_template: groceries_template
)
# => #<Envelope id: 1, monthly_budget_id: 1, envelope_template_id: 1, allotted_amount: 500.00, ...>

# Or explicitly set the amount (overrides default)
envelope = budget.envelopes.create(
  envelope_template: groceries_template,
  allotted_amount: 600.00
)
# => #<Envelope ... allotted_amount: 600.00>

# Access the name (from template, unless overridden)
envelope.name  # => "Groceries"
envelope.display_name  # => "Groceries" (or "Groceries (Savings)" if savings)
envelope.spending_group_name  # => "Groceries" (alias for name)

# Create envelope with name override
custom_envelope = budget.envelopes.create(
  envelope_template: groceries_template,
  name: "Custom Groceries",  # Override template name
  allotted_amount: 600.00
)
custom_envelope.name  # => "Custom Groceries" (override)
custom_envelope.variable?  # => true (from template - cannot override)
```

### Creating a Fixed Expense Envelope

```ruby
budget = MonthlyBudget.first
rent_template = budget.user.envelope_templates.find_or_create_by!(name: "Rent") do |et|
  et.group_type = :fixed
  et.is_savings = false
end

rent_envelope = budget.envelopes.create(
  envelope_template: rent_template,
  allotted_amount: 1200.00
)

# Add spending records
rent_envelope.spendings.create!(amount: 1200.00, spent_on: Date.today)
rent_envelope.spent_amount  # => 1200.00 (calculated)
```

### Creating a Savings Envelope

```ruby
budget = MonthlyBudget.first
emergency_template = budget.user.envelope_templates.find_or_create_by!(name: "Emergency Fund") do |et|
  et.group_type = :fixed
  et.is_savings = true
end

emergency_fund = budget.envelopes.create(
  envelope_template: emergency_template,
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
  envelope_template: template,
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
rent_template = budget.user.envelope_templates.find_or_create_by!(name: "Rent") do |et|
  et.group_type = :fixed
  et.default_amount = 1200.00
end

rent_envelope = budget.envelopes.create(envelope_template: rent_template)
rent_envelope.allotted_amount  # => 1200.00 (from category default)

# Not paid yet
rent_envelope.paid?  # => false

# Add spending equal to allotted amount
rent_envelope.spendings.create!(amount: 1200.00, spent_on: Date.today)
rent_envelope.paid?  # => true

# Variable expenses are never "paid"
groceries_template = budget.user.envelope_templates.find_or_create_by!(name: "Groceries") do |et|
  et.group_type = :variable
end
groceries_envelope = budget.envelopes.create(
  envelope_template: groceries_template,
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
template = budget.user.envelope_templates.first

# Duplicate envelope template in same budget
duplicate = budget.envelopes.create(
  envelope_template: template  # if already exists
)
# => #<Envelope ... errors: {:envelope_template_id=>["already has an envelope for this template in this budget"]}>

# Negative allotted amount
negative_amount = budget.envelopes.create(
  envelope_template: template,
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

