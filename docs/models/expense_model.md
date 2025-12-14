# ExpenseModel Documentation

## Overview

The Expensemodel represents payment categories within a monthly budget in the Willow application. Expense are a budgeting method where money is allocated to different payment categories (like "Groceries", "Rent", "Entertainment"). Each expensetracks how much was allotted for the month and how much has actually been spent.

## Database Table

**Table Name:** `expense`

### Schema

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | Primary Key | Auto-incrementing unique identifier |
| `monthly_budget_id` | bigint | NOT NULL, Foreign Key | References the monthly budget this expensebelongs to |
| `expense_template_id` | bigint | NOT NULL, Foreign Key | References the expensetemplate this expenseis based on |
| `allotted_amount` | decimal(12,2) | NOT NULL, Default: 0.0 | How much the user assigned to this expensethis month |
| `name` | string | Nullable | Override field: Custom name for this expense(uses template name if null) |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Last update timestamp |

### Indexes

- **Monthly Budget ID + ExpenseTemplate ID Index**: Unique composite index on `[monthly_budget_id, expense_template_id]` - ensures one expenseper template per budget (unless name override is used)
- **Monthly Budget ID Index**: Index on `monthly_budget_id` for fast budget lookups
- **ExpenseTemplate ID Index**: Index on `expense_template_id` for fast template lookups
- **Monthly Budget ID + Name Index**: Composite index on `[monthly_budget_id, name]` - for name override lookups

### Foreign Keys

- `expense.monthly_budget_id` references `monthly_budgets.id` with `on_delete: :cascade`. If a monthly budget is deleted, all its expense are deleted.
- `expense.expense_template_id` references `expense_templates.id` with `on_delete: :cascade`. If an expensetemplate is deleted, all its expense are deleted.

## Model Location

`app/models/expenserb`

## Associations

### Belongs To

- **Monthly Budget**: Each expensebelongs to exactly one monthly budget
  ```ruby
  expensemonthly_budget  # Returns the MonthlyBudget object
  ```

- **ExpenseTemplate**: Each expensebelongs to exactly one expensetemplate
  ```ruby
  expenseexpense_template  # Returns the ExpenseTemplate object
  ```

### Has Many

- **Payments**: Each expensecan have many payment records
  ```ruby
  expensepayments  # Returns collection of Payment objects
  ```
  - **Dependent Behavior**: `destroy` - when an expenseis deleted, all its payment records are deleted

### Has Many (from Monthly Budget)

- **MonthlyBudget has_many :expense**: A monthly budget can have multiple expense
  ```ruby
  monthly_budget.expense  # Returns collection of Expenseobjects
  ```
  - **Dependent Behavior**: `destroy` - when a monthly budget is deleted, all its expense are deleted

## Validations

### Numericality Validations

- `validates :allotted_amount, numericality: { greater_than_or_equal_to: 0 }`:
  - `allotted_amount` must be a number greater than or equal to 0.

### Uniqueness Validations

- `validates :expense_template_id, uniqueness: { scope: :monthly_budget_id }`:
  - A monthly budget can only have one expensefor each expensetemplate (unless name override is used).
  - Prevents duplicate templates within the same budget.
- `validates :name, uniqueness: { scope: :monthly_budget_id }` (if name override is used):
  - If using a name override, the name must be unique within the monthly budget.

### Database Constraints

- **Unique Constraint**: The database enforces uniqueness on `[monthly_budget_id, expense_template_id]` - a monthly budget can only have one expenseper template (unless name override is used).

## Callbacks

- `before_validation :set_default_allotted_amount, on: :create`:
  - Automatically sets `allotted_amount` from the expensetemplate's `default_amount` when creating a new expense
  - Only applies if `allotted_amount` is not explicitly set.
  - If template's `default_amount` is `nil`, defaults to `0.0`.

## Scopes

- `scope :by_frequency`: Returns expenses filtered by frequency (delegates to template).
- `scope :over_budget`: Returns only expense where the sum of payment amounts exceeds the allotted amount. Uses a SQL subquery for efficient database-level filtering.

## Instance Methods

### Accessing Template Properties

- `name`: Returns the override name if present, otherwise returns the template name.
- `display_name`: Returns a friendly display name.
- `frequency`: Returns the expense template's frequency (always from template).
- `due_date`: Returns the expense template's due date (always from template).
- `frequency_text`: Returns a human-readable text description of the frequency ("Monthly", "Weekly", etc.).

### Name Override Checking

- `has_overrides?`: Returns `true` if the expensehas a name override.
- `name_overridden?`: Returns `true` if the name is overridden.

### Financial Calculations

- `spent_amount`: **Calculated method** - Returns the sum of all payment records for this expense(`payments.sum(:amount)`).
- `remaining`: Returns `allotted_amount - spent_amount` (can be negative if over budget).
- `available`: Returns the available amount (never negative). If `remaining` is negative, returns 0.
- `over_budget?`: Returns `true` if `spent_amount > allotted_amount`.
- `under_budget?`: Returns `true` if `spent_amount < allotted_amount`.
- `paid?`: Returns `true` for fixed bills when `spent_amount >= allotted_amount`. Always returns `false` for variable expenses.
- `spent_percentage`: Returns the percentage of allotted amount that has been spent (capped at 100%, returns decimal). Safely handles zero and negative allotted amounts by returning 0.
- `percent_used`: Returns the percentage of allotted amount that has been spent (integer, rounded, not capped).

### Display Helpers

- `display_name_with_budget`: Returns a string combining the expensename and budget month/year (e.g., "Groceries (2025-12)").
- `to_s`: Returns a friendly string representation for debugging/selects (e.g., "Groceries (December 2025)").

## Business Rules

1. **One ExpensePer Payment Category Per Budget**: Each monthly budget can only have one expensefor a given payment category. Different budgets can use the same payment category.

2. **Name from Template**: The expense name can optionally be overridden on a per-expense basis. If the name override is not set, the template's name is used. Frequency and due date always come from the template.

3. **Spent Amount is Calculated**: The `spent_amount` is calculated from the sum of all related payment records. It is not stored in the database and updates automatically as payment records are added or removed.

4. **Non-Negative Allotted Amount**: `allotted_amount` cannot be negative (zero is allowed).

5. **Default Values**: 
   - New expense automatically get `allotted_amount` from the expensetemplate's `default_amount` (if set).
   - If template's `default_amount` is `nil` or not set, defaults to `0.0`.
   - Explicitly set `allotted_amount` values are not overridden by the default.
   - `spent_amount` always starts at 0.0 (when there are no payment records)
   - The `name` override field defaults to `nil` and uses the template name when not set.
   - `frequency` and `due_date` always come from the template (not overrideable).

6. **Cascade Deletion**: 
   - Deleting a monthly budget will delete all its associated expense.
   - Deleting an expensetemplate will delete all associated expense.
   - Deleting an expensewill delete all its associated payment records.

## Usage Examples

### Creating an Expense

```ruby
budget = MonthlyBudget.first
groceries_template = budget.user.expense_templates.find_or_create_by!(name: "Groceries") do |et|
  et.frequency = "monthly"
  et.default_amount = 500.00
end

# Create expense - allotted_amount will be auto-filled from template default_amount
expense = budget.expenses.create(
  expense_template: groceries_template
)
# => #<Expense id: 1, monthly_budget_id: 1, expense_template_id: 1, allotted_amount: 500.00, ...>

# Or explicitly set the amount (overrides default)
expense = budget.expenses.create(
  expense_template: groceries_template,
  allotted_amount: 600.00
)
# => #<Expense... allotted_amount: 600.00>

# Access the name (from template, unless overridden)
expense.name  # => "Groceries"
expense.display_name  # => "Groceries"
expense.frequency  # => "monthly" (from template)

# Create expense with name override
custom_expense = budget.expenses.create(
  expense_template: groceries_template,
  name: "Custom Groceries",  # Override template name
  allotted_amount: 600.00
)
custom_expense.name  # => "Custom Groceries" (override)
custom_expense.frequency  # => "monthly" (from template - cannot override)
```

### Creating an Expense with Due Date

```ruby
budget = MonthlyBudget.first
rent_template = budget.user.expense_templates.find_or_create_by!(name: "Rent") do |et|
  et.frequency = "monthly"
  et.due_date = Date.new(2025, 1, 1)
end

rent_expense = budget.expenses.create(
  expense_template: rent_template,
  allotted_amount: 1200.00
)

# Access frequency and due date from template
rent_expense.frequency  # => "monthly"
rent_expense.due_date   # => #<Date: 2025-01-01>

# Add payment records
rent_expense.payments.create!(amount: 1200.00, spent_on: Date.today)
rent_expense.spent_amount  # => 1200.00 (calculated)
```

### Retrieving Expenses by Frequency

```ruby
budget = MonthlyBudget.first

monthly_expenses = budget.expenses.by_frequency("monthly")
# => #<ActiveRecord::Relation [#<Expense... frequency: "monthly">, ...]>

weekly_expenses = budget.expenses.by_frequency("weekly")
# => #<ActiveRecord::Relation [#<Expense... frequency: "weekly">, ...]>

# Find expenses that are over budget (efficient database query)
over_budget_expenses = budget.expenses.over_budget
# => #<ActiveRecord::Relation [#<Expense... spent > allotted>, ...]>
```

### Calculating Remaining and Available Amounts

```ruby
expense= Expensefirst
# => #<Expense... allotted_amount: 500.00>

# Create some payment records
expensepayments.create!(amount: 100.00, spent_on: Date.today)
expensepayments.create!(amount: 50.00, spent_on: Date.today)
expensespent_amount  # => 150.00 (calculated from payments)

expenseremaining  # => 350.00 (allotted_amount - spent_amount)
expenseavailable  # => 350.00
expenseover_budget?  # => false

# Over budget example
over_budget_expense= Expensecreate!(
  monthly_budget: budget,
  expense_template: template,
  allotted_amount: 100.00
)
over_budget_expensepayments.create!(amount: 150.00, spent_on: Date.today)
over_budget_expensespent_amount  # => 150.00

over_budget_expenseremaining  # => -50.00
over_budget_expenseavailable  # => 0.00 (never negative)
over_budget_expenseover_budget?  # => true
```

### Calculating Spent Percentage

```ruby
expense= Expensefirst
expenseallotted_amount  # => 500.00
expensepayments.create!(amount: 320.50, spent_on: Date.today)
expensespent_amount  # => 320.50

expensespent_percentage  # => 64.1 (decimal, capped at 100%)
expensepercent_used  # => 64 (integer, rounded, not capped)

# Fully spent
expensepayments.create!(amount: 179.50, spent_on: Date.today)
expensespent_amount  # => 500.00
expensespent_percentage  # => 100.0 (capped at 100%)
expensepercent_used  # => 100 (integer)
```

### Checking if Expense is Paid

```ruby
budget = MonthlyBudget.first
rent_template = budget.user.expense_templates.find_or_create_by!(name: "Rent") do |et|
  et.frequency = "monthly"
  et.default_amount = 1200.00
end

rent_expense = budget.expenses.create(expense_template: rent_template)
rent_expense.allotted_amount  # => 1200.00 (from template default)

# Not paid yet
rent_expense.paid?  # => false

# Add payment equal to allotted amount
rent_expense.payments.create!(amount: 1200.00, spent_on: Date.today)
rent_expense.paid?  # => true (spent >= allotted)

# Expense is considered paid when spent >= allotted
groceries_template = budget.user.expense_templates.find_or_create_by!(name: "Groceries") do |et|
  et.frequency = "monthly"
end
groceries_expense = budget.expenses.create(
  expense_template: groceries_template,
  allotted_amount: 500.00
)
groceries_expense.payments.create!(amount: 500.00, spent_on: Date.today)
groceries_expense.paid?  # => true (spent >= allotted)
```

### Display Methods

```ruby
expense= Expensefirst

# String representation for debugging/selects
expenseto_s  # => "Groceries (December 2025)"

# Display name with budget month
expensedisplay_name_with_budget  # => "Groceries (2025-12)"
```

### Handling Validation Errors

```ruby
budget = MonthlyBudget.first
template = budget.user.expense_templates.first

# Duplicate expensetemplate in same budget
duplicate = budget.expense.create(
  expense_template: template  # if already exists
)
# => #<Expense... errors: {:expense_template_id=>["already has an expensefor this template in this budget"]}>

# Negative allotted amount
negative_amount = budget.expense.create(
  expense_template: template,
  allotted_amount: -100.00
)
# => #<Expense... errors: {:allotted_amount=>["must be greater than or equal to 0"]}>
```

## Key Concepts

### Expense Frequency

Expenses can have different frequencies that indicate how often they occur:
- **Monthly**: Recurring monthly expenses (e.g., rent, subscriptions)
- **Weekly**: Recurring weekly expenses (e.g., groceries)
- **Biweekly**: Recurring biweekly expenses (e.g., paychecks used for expenses)
- **Yearly**: Recurring yearly expenses (e.g., insurance premiums, annual subscriptions)

The frequency helps users understand the payment cadence and plan their budgets accordingly.

### ExpenseBudgeting Method

The expensemethod is a budgeting technique where income is divided into categories (expense) and payment is tracked against each category. This helps users:
- Stay within budget for each category
- See exactly where money is going
- Make informed decisions about discretionary payment
- Build savings systematically

### Relationship to Monthly Budget

- Each expensebelongs to a specific monthly budget
- The sum of `allotted_amount` across all expense should typically match or be less than `monthly_budget.total_actual_income`
- The `monthly_budget.remaining` method calculates `total_actual_income - total_allotted` to show unassigned money

## Admin Dashboard

Expense can be managed through the admin dashboard:
- **View All**: `/admin/expenses`
- **View Details**: `/admin/expenses/:id`
- **Edit**: `/admin/expenses/:id/edit`
- **Create**: `/admin/expenses/new`

The admin dashboard displays:
- Total count of expense
- Recent expense
- Ability to create, edit, and delete expense

## Migration History

- `20251210005820_create_expense.rb` - Initial expense table creation

## Future Enhancements

- **Automatic Payment Tracking**: Integrate with transaction import to automatically update `spent_amount`
- **Recurring Expense**: Copy expensestructure from previous month
- **ExpenseTemplates**: Pre-defined expensesets for common budgeting styles
- **Payment Alerts**: Notify users when approaching or exceeding expenselimits
- **ExpenseGoals**: Track progress toward savings goals
- **Color Coding**: Visual indicators for expensetypes and status
- **Payment Trends**: Show payment patterns over time for each envelope
- **ExpenseRollover**: Carry over unspent amounts to next month (optional)
- **Budget Recommendations**: Suggest expenseallocations based on income

---

**Last Updated**: December 2025

