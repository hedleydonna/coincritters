# ExpenseModel Documentation

## Overview

The Expense model represents payment categories within a monthly budget in the CoinCritters application. Expenses are a budgeting method where money is allocated to different payment categories (like "Groceries", "Rent", "Entertainment"). Each expense tracks how much was allotted for the month and how much has actually been spent.

## Database Table

**Table Name:** `expenses`

### Schema

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | Primary Key | Auto-incrementing unique identifier |
| `monthly_budget_id` | bigint | NOT NULL | References the monthly budget this expensebelongs to (referential integrity enforced at model level) |
| `expense_template_id` | bigint | Nullable | References the expensetemplate this expenseis based on (nullable for one-off expenses, referential integrity enforced at model level) |
| `allotted_amount` | decimal(12,2) | NOT NULL, Default: 0.0 | How much the user assigned to this expensethis month |
| `name` | string | Required | Expense name (copied from template when created from template, or user-provided for one-off expenses) |
| `expected_on` | date | Nullable | Expected date for this expense (used for weekly/bi-weekly expenses to track individual payment dates) |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Last update timestamp |

### Indexes

- **Monthly Budget ID Index**: Index on `monthly_budget_id` for fast budget lookups
- **ExpenseTemplate ID Index**: Index on `expense_template_id` for fast template lookups (non-unique - allows multiple expenses per template)
- **Expected On Index**: Index on `expected_on` for date-based queries

### Referential Integrity

**Note:** This codebase does not use database-level foreign key constraints. Referential integrity is enforced at the model level via `belongs_to` validations in Rails 5+.

- `expense.monthly_budget_id` references `monthly_budgets.id` - enforced via `belongs_to :monthly_budget` validation
- `expense.expense_template_id` references `expense_templates.id` (nullable) - enforced via `belongs_to :expense_template, optional: true` validation

Cascade deletion is handled via `dependent: :destroy` in model associations, not database-level foreign keys.

## Model Location

`app/models/expense.rb`

## Associations

### Belongs To

- **Monthly Budget**: Each expense belongs to exactly one monthly budget
  ```ruby
  expense.monthly_budget  # Returns the MonthlyBudget object
  ```

- **ExpenseTemplate**: Each expense can optionally belong to an expense template (nullable association for one-off expenses)
  ```ruby
  expense.expense_template  # Returns the ExpenseTemplate object, or nil for one-off expenses
  ```

### Has Many

- **Payments**: Each expense can have many payment records
  ```ruby
  expense.payments  # Returns collection of Payment objects
  ```
  - **Dependent Behavior**: `destroy` - when an expense is deleted, all its payment records are deleted

### Has One Through

- **User**: Each expense has access to its user through the monthly budget
  ```ruby
  expense.user  # Returns the User object
  ```

### Has Many (from Monthly Budget)

- **MonthlyBudget has_many :expenses**: A monthly budget can have multiple expenses
  ```ruby
  monthly_budget.expenses  # Returns collection of Expense objects
  ```
  - **Dependent Behavior**: `destroy` - when a monthly budget is deleted, all its expenses are deleted

## Validations

### Numericality Validations

- `validates :allotted_amount, numericality: { greater_than_or_equal_to: 0 }`:
  - `allotted_amount` must be a number greater than or equal to 0.

### Presence Validations

- `validates :name, presence: true`:
  - Name is always required for all expenses.
  - For template-based expenses, the template name is automatically copied to `expense.name` when the expense is created.
  - For one-off expenses, the user must provide a name.

### Uniqueness Validations

- **No uniqueness constraints**: Multiple expenses can share the same name within a budget, and multiple expenses can be created from the same template within a budget (needed for weekly/bi-weekly expenses that create multiple expense records per month).

## Callbacks

- `before_validation :set_default_allotted_amount, on: :create, if: -> { expense_template_id.present? }`:
  - Automatically sets `allotted_amount` from the expense template's `default_amount` when creating a new expense with a template
  - Only applies if expense has a template and `allotted_amount` is nil or zero (not explicitly set).
  - If template's `default_amount` is `nil`, defaults to `0.0`.
  - Does not apply to one-off expenses (no template).
  - Reloads the expense_template to ensure default_amount is available.

## Scopes

- `scope :by_frequency`: Returns expenses filtered by frequency (delegates to template).
- `scope :over_budget`: Returns only expense where the sum of payment amounts exceeds the allotted amount. Uses a SQL subquery for efficient database-level filtering.

## Instance Methods

### Accessing Template Properties

- `name`: Returns the expense's stored name (copied from template when created, or user-provided for one-offs). No longer falls back to template name.
- `display_name`: Returns a friendly display name (same as `name`).
- `frequency`: Returns the expense template's frequency (always from template).
- `due_date`: Returns `expected_on` if present (for weekly/bi-weekly expenses), otherwise returns the expense template's `due_date`.
- `frequency_text`: Returns a human-readable text description of the frequency ("Monthly", "Weekly", etc.).

### Financial Calculations

- `spent_amount`: **Calculated method** - Returns the sum of all payment records for this expense(`payments.sum(:amount)`).
- `remaining`: Returns `allotted_amount - spent_amount` (can be negative if over budget).
- `available`: Returns the available amount (never negative). If `remaining` is negative, returns 0.
- `over_budget?`: Returns `true` if `spent_amount > allotted_amount`.
- `under_budget?`: Returns `true` if `spent_amount < allotted_amount`.
- `paid?`: Returns `true` when `spent_amount >= allotted_amount` (expense is fully paid).
- `spent_percentage`: Returns the percentage of allotted amount that has been spent (capped at 100%, returns decimal). Safely handles zero and negative allotted amounts by returning 0.
- `percent_used`: Returns the percentage of allotted amount that has been spent (integer, rounded, not capped).

### Display Helpers

- `display_name_with_budget`: Returns a string combining the expensename and budget month/year (e.g., "Groceries (2025-12)").
- `to_s`: Returns a friendly string representation for debugging/selects (e.g., "Groceries (December 2025)").

## Business Rules

1. **Two Types of Expenses**:
   - **Template-based expenses**: Created from an expense template (recurring expenses like "Rent", "Groceries")
   - **One-off expenses**: Created without a template for unique, non-recurring expenses (e.g., "Birthday Gift", "Car Repair")

2. **Name Methodology**:
   - **Template-based expenses**: When created from a template, the template's name is automatically copied into `expense.name`. This allows each expense to have its own editable name that can be customized independently of the template.
   - **One-off expenses**: User must provide a name when creating the expense.
   - **Multiple expenses with same name**: Multiple expenses can share the same name within a budget (no uniqueness constraint).
   - **Multiple expenses per template**: Multiple expenses can be created from the same template within a budget (needed for weekly/bi-weekly templates that create multiple expense records per month).

3. **Name Requirements**:
   - **All expenses**: `name` is always required
   - **Template-based expenses**: Name is automatically copied from template when expense is created, but can be edited later
   - **One-off expenses**: User must provide a name when creating

4. **Template Association**:
   - Template-based expenses: Must have an `expense_template_id`
   - One-off expenses: `expense_template_id` is null
   - Frequency and due_date come from the template (for template-based expenses) or default to "monthly" and nil (for one-off expenses)
   - For weekly/bi-weekly expenses, each expense record has its own `expected_on` date to track individual payment dates

5. **Spent Amount is Calculated**: The `spent_amount` is calculated from the sum of all related payment records. It is not stored in the database and updates automatically as payment records are added or removed.

6. **Non-Negative Allotted Amount**: `allotted_amount` cannot be negative (zero is allowed).

7. **Default Values**: 
   - Template-based expenses: Automatically get `allotted_amount` from the expense template's `default_amount` (if set, otherwise 0.0)
   - One-off expenses: Default `allotted_amount` is 0.0 (must be explicitly set)
   - Explicitly set `allotted_amount` values are not overridden by the default
   - `spent_amount` always starts at 0.0 (when there are no payment records)

8. **Cascade Deletion**: 
   - Deleting a monthly budget will delete all its associated expenses (both template-based and one-off) via `dependent: :destroy` in `MonthlyBudget`
   - Deleting an expense template will delete all associated template-based expenses via `dependent: :destroy` in `ExpenseTemplate` (one-off expenses are not affected)
   - Deleting an expense will delete all its associated payment records via `dependent: :destroy` in `Expense`
   - All cascade deletion is handled at the application level, not via database foreign key constraints

## Usage Examples

### Creating a Template-Based Expense

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

# Template name is automatically copied to expense.name
expense = budget.expenses.create(
  expense_template: groceries_template,
  allotted_amount: 600.00
)
expense.name  # => "Groceries" (copied from template)
# Name can be edited later if needed
expense.update(name: "Custom Groceries")
expense.name  # => "Custom Groceries" (now customized)
expense.frequency  # => "monthly" (from template - cannot override)
```

### Creating a One-Off Expense

```ruby
budget = MonthlyBudget.first

# Create a one-off expense without a template
one_off_expense = budget.expenses.create(
  name: "Birthday Gift",
  allotted_amount: 50.00
)
# => #<Expense id: 2, monthly_budget_id: 1, expense_template_id: nil, name: "Birthday Gift", allotted_amount: 50.00, ...>

one_off_expense.name  # => "Birthday Gift"
one_off_expense.expense_template  # => nil
one_off_expense.frequency  # => "monthly" (default when no template)
one_off_expense.due_date  # => nil

# Create another one-off expense
car_repair = budget.expenses.create(
  name: "Car Repair",
  allotted_amount: 300.00
)
# => #<Expense... expense_template_id: nil, name: "Car Repair" ...>

# One-off expenses can have duplicate names across different budgets
other_budget = MonthlyBudget.create!(user: budget.user, month_year: "2026-01")
another_gift = other_budget.expenses.create(
  name: "Birthday Gift",  # Same name, different budget - OK!
  allotted_amount: 75.00
)
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

## Testing Script: Create Past Months Data

Use this script in the Rails console to create 3 past months of realistic test data:

```ruby
# Create 3 past months of test data for a user
# Run in Rails console: rails console
# Usage: user = User.find_by(email: "your@email.com"); load 'path/to/script.rb'

def create_past_months_test_data(user)
  # Create expense templates if they don't exist
  # Note: due_date should be a full Date object, or nil if not specified
  templates = [
    { name: "Rent", frequency: "monthly", default_amount: 1200.00, due_date: Date.today.beginning_of_month + 0.days },
    { name: "Groceries", frequency: "monthly", default_amount: 500.00 },
    { name: "Utilities", frequency: "monthly", default_amount: 150.00, due_date: Date.today.beginning_of_month + 14.days },
    { name: "Phone", frequency: "monthly", default_amount: 80.00, due_date: Date.today.beginning_of_month + 4.days },
    { name: "Transportation", frequency: "monthly", default_amount: 200.00 }
  ]
  
  templates.each do |template_attrs|
    user.expense_templates.find_or_create_by!(name: template_attrs[:name]) do |template|
      template.frequency = template_attrs[:frequency] || "monthly"
      template.default_amount = template_attrs[:default_amount] || 0
      template.due_date = template_attrs[:due_date] if template_attrs[:due_date]
      template.auto_create = true
      template.is_active = true
    end
  end
  
  # Create 3 past months
  (1..3).each do |months_ago|
    month_year = (Date.today - months_ago.months).strftime("%Y-%m")
    
    # Skip if budget already exists
    next if user.monthly_budgets.exists?(month_year: month_year)
    
    # Create monthly budget
    budget = user.monthly_budgets.create!(
      month_year: month_year,
      total_actual_income: 3500.00 + (rand * 500) # Vary income between 3500-4000
    )
    
    # Auto-create expenses from templates
    budget.auto_create_expenses
    
    # Adjust some expenses with realistic variations
    budget.expenses.each do |expense|
      # Randomly vary amounts by ±10%
      variation = 1 + (rand * 0.2 - 0.1) # -10% to +10%
      expense.update!(allotted_amount: (expense.allotted_amount * variation).round(2))
    end
    
    # Add some payments to make it realistic
    # Sample 3-5 expenses (or all if less than 3)
    expenses_to_pay = budget.expenses.count >= 3 ? budget.expenses.sample(rand(3..5)) : budget.expenses.to_a
    expenses_to_pay.each do |expense|
      # Create 1-3 payments per expense
      payment_count = rand(1..3)
      payment_count.times do
        # Random date within the month
        month_start = Date.parse("#{month_year}-01")
        month_end = month_start.end_of_month
        random_date = month_start + rand((month_end - month_start).to_i).days
        
        # Payment amount: 20-100% of allotted amount
        payment_amount = (expense.allotted_amount * (0.2 + rand * 0.8)).round(2)
        
        expense.payments.create!(
          amount: payment_amount,
          spent_on: random_date,
          notes: ["Weekly groceries", "Gas fill-up", "Monthly payment", nil].sample
        )
      end
    end
    
    puts "Created budget for #{budget.name} with #{budget.expenses.count} expenses and #{budget.total_spent.round(2)} spent"
  end
  
  puts "\n✅ Created 3 past months of test data for #{user.email}"
  puts "   Budgets: #{user.monthly_budgets.where('month_year < ?', Date.today.strftime('%Y-%m')).count}"
  puts "   Total expenses: #{user.expenses.joins(:monthly_budget).where('monthly_budgets.month_year < ?', Date.today.strftime('%Y-%m')).count}"
  puts "   Total payments: #{Payment.joins(expense: :monthly_budget).where('monthly_budgets.user_id = ? AND monthly_budgets.month_year < ?', user.id, Date.today.strftime('%Y-%m')).count}"
end

# Example usage:
# user = User.first
# create_past_months_test_data(user)
```

**To use this script in Rails console:**

✅ **Yes, this script is designed to run directly in the Rails console!**

**Steps:**

1. Open Rails console: `rails console`

2. Copy and paste the entire function definition (everything from `def create_past_months_test_data(user)` to the `end`)

3. Find your user and run:
   ```ruby
   user = User.first  # or User.find_by(email: "your@email.com")
   create_past_months_test_data(user)
   ```

**Example in Rails console:**
```ruby
# After pasting the function definition above:
rails> user = User.first
rails> create_past_months_test_data(user)
Created budget for October 2025 with 5 expenses and 1250.50 spent
Created budget for November 2025 with 5 expenses and 980.25 spent
Created budget for December 2025 with 5 expenses and 1450.75 spent

✅ Created 3 past months of test data for user@example.com
   Budgets: 3
   Total expenses: 15
   Total payments: 12
```

This script will:
- Create 5 common expense templates (Rent, Groceries, Utilities, Phone, Transportation)
- Create 3 past months of budgets with varied income
- Auto-populate expenses from templates with slight variations
- Add realistic payment records with random dates and amounts
- Display summary statistics

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

