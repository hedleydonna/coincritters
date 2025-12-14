# ExpenseTemplate Model Documentation

## Overview

The `ExpenseTemplate` model represents user-defined templates that can be reused across monthly budgets to create expense. Each template defines the frequency of payment (monthly, weekly, biweekly, yearly), optional due date, default amounts, and auto-creation behavior. Expense reference expensetemplates to inherit their properties, but can override name on a per-month basis.

## Model Location

`app/models/expense_template.rb`

## Schema

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | Primary Key | Auto-incrementing unique identifier |
| `user_id` | bigint | NOT NULL | References the user who owns this template (referential integrity enforced at model level) |
| `name` | string | NOT NULL | Template name (e.g., "Rent", "Groceries", "Emergency Fund") |
| `frequency` | string | NOT NULL, Default: "monthly" | Payment frequency: "monthly", "weekly", "biweekly", or "yearly" |
| `due_date` | date | Nullable | Optional due date for this expense |
| `default_amount` | decimal(12,2) | Nullable | Default amount to allocate when creating expense |
| `auto_create` | boolean | NOT NULL, Default: true | Automatically create expensein monthly budgets |
| `is_active` | boolean | NOT NULL, Default: true | Whether the template is active (soft delete) |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Last update timestamp |

### Indexes

- **User ID + Name Index**: Composite unique index on `[user_id, name]` - ensures unique template names per user (only among active templates)
- **Is Active Index**: Index on `is_active` - optimized for filtering active/inactive templates

### Referential Integrity

**Note:** This codebase does not use database-level foreign key constraints. Referential integrity is enforced at the model level via `belongs_to` validations in Rails 5+.

- `expense_templates.user_id` references `users.id` - enforced via `belongs_to :user` validation

Cascade deletion is handled via `dependent: :destroy` in model associations, not database-level foreign keys.

## Associations

### Belongs To

- `belongs_to :user` - Each expensetemplate belongs to a user who owns it

### Has Many

- `has_many :expense, dependent: :destroy` - An expensetemplate can have many expense across different monthly budgets. When a template is hard deleted (by admin only), all associated expense are deleted. Soft delete (deactivation) preserves expense.

## Validations

### Presence Validations

- `validates :name, presence: true` - The template name must be present.

### Uniqueness Validations

- `validates :name, uniqueness: { scope: :user_id, conditions: -> { where(is_active: true) } }` - Template names must be unique per user among active templates. Different users can have templates with the same name. Inactive templates don't count toward uniqueness, allowing the same name to be reused after deactivation.

### Numericality Validations

- `validates :default_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true` - The default amount must be greater than or equal to 0 if provided, but can be nil.

### Inclusion Validations

- `validates :frequency, inclusion: { in: %w[monthly weekly biweekly yearly] }` - The frequency must be one of the valid values: "monthly", "weekly", "biweekly", or "yearly". Defaults to "monthly" if not specified.

## Default Scope

- `default_scope -> { order(:name) }` - All queries are ordered alphabetically by name by default. Use `.reorder()` to override this ordering when needed (e.g., `ExpenseTemplate.active.reorder(created_at: :desc)`).

## Scopes

- `scope :active` - Returns only active templates (`is_active: true`)
- `scope :inactive` - Returns only inactive templates (`is_active: false`)
- `scope :auto_create` - Returns only templates with `auto_create: true`
- `scope :by_frequency` - Returns templates with a specific frequency (e.g., `ExpenseTemplate.by_frequency("monthly")`)

**Note:** Most queries should use `.active` to only show active templates. The `active` scope should be chained with other scopes (e.g., `ExpenseTemplate.active.by_frequency("monthly")`). To override the default alphabetical ordering, use `.reorder()` (e.g., `ExpenseTemplate.active.reorder(created_at: :desc)`).

## Instance Methods

- `display_name` - Returns the template name (same as `name`).
  
- `frequency_text` - Returns a human-readable text description of the frequency:
  - `"Monthly"` for monthly templates
  - `"Weekly"` for weekly templates
  - `"Biweekly"` for biweekly templates
  - `"Yearly"` for yearly templates
  - Defaults to `"Monthly"` if frequency is not set

- `deactivate!` - Soft deletes the template by setting `is_active` to `false`. Preserves the template and all associated expense for historical purposes.

- `activate!` - Reactivates a deactivated template by setting `is_active` to `true`.

- `active?` - Returns `true` if the template is active, `false` otherwise. Alias for `is_active?`.

## Business Rules

1. **Unique Names Per User**: Each user can only have one template with a given name. Different users can have templates with the same name.

2. **Frequency**: Templates specify how often the expense occurs (monthly, weekly, biweekly, or yearly). This helps users understand the payment cadence.

3. **Due Dates**: Templates can optionally specify a due date, which helps users track when payments are typically due.

4. **Default Amounts**: Templates can have a default amount that will be used when automatically creating expense in monthly budgets.

5. **Auto-Create**: When `auto_create` is true, the system will automatically create expense from this template in monthly budgets using the `MonthlyBudget#auto_create_expense` method. Only active templates are used for auto-creation.

6. **Soft Delete (is_active)**: Templates use soft delete via the `is_active` field. When a template is "deleted", it's actually deactivated (`is_active: false`) rather than removed from the database. This preserves:
   - Historical data integrity
   - Existing expense that reference the template
   - Ability to reactivate templates if needed
   - No cascade deletion issues

7. **Active Templates Only**: Most queries should filter to active templates using `.active`. Inactive templates are hidden from normal views but can still be accessed by admins.

8. **Cascade Deletion**: 
   - **User Deletion**: When a user account is deleted (by admin), all their expensetemplates are automatically deleted via `dependent: :destroy` in the `User` model association.
   - **Template Hard Delete**: When an expensetemplate is actually destroyed (hard delete, not just deactivated), all associated expense are deleted via `dependent: :destroy`. **Note:** Only admins can perform hard deletes on templates. Regular users can only soft delete (deactivate) templates.

9. **Default Ordering**: All queries are ordered alphabetically by name by default. This provides consistent, user-friendly ordering in dropdowns and lists. Use `.reorder()` to override when needed (e.g., to show newest first).

## Usage Examples

### Creating an ExpenseTemplate

```ruby
user = User.find(1)

# Create a monthly expensetemplate for rent
rent_template = ExpenseTemplate.create!(
  user: user,
  name: "Rent",
  frequency: "monthly",
  due_date: Date.new(2025, 1, 1), # First of the month
  default_amount: 1200.00,
  auto_create: true
)

# Create a weekly expensetemplate for groceries
groceries_template = ExpenseTemplate.create!(
  user: user,
  name: "Groceries",
  frequency: "weekly",
  default_amount: 500.00,
  auto_create: true
)

# Create a yearly template for insurance
insurance = ExpenseTemplate.create!(
  user: user,
  name: "Car Insurance",
  frequency: "yearly",
  due_date: Date.new(2025, 6, 15),
  default_amount: 1200.00,
  auto_create: true
)
```

### Finding Templates

```ruby
user = User.find(1)

# Find all active monthly templates
monthly_templates = user.expense_templates.active.by_frequency("monthly")

# Find all active weekly templates
weekly_templates = user.expense_templates.active.by_frequency("weekly")

# Find a specific active template
rent = user.expense_templates.active.find_by(name: "Rent")

# Find inactive templates (admin use)
inactive_templates = user.expense_templates.inactive
```

### Using with Expense

```ruby
template = ExpenseTemplate.find(1)
monthly_budget = MonthlyBudget.find(1)

# Create an expenseusing this template
expense= Expensecreate!(
  monthly_budget: monthly_budget,
  expense_template: template,
  # Name comes from the template (unless overridden)
  allotted_amount: template.default_amount || 0
)

# The expenseinherits frequency and due_date from the template
expense.frequency  # => "monthly" (from template)
expense.due_date   # => Date object (from template, if set)

# Create an expensewith name override
custom_expense= Expensecreate!(
  monthly_budget: monthly_budget,
  expense_template: template,
  name: "Custom Name",  # Override template name
  allotted_amount: 600.00
)
```

### Display Methods

```ruby
template = ExpenseTemplate.find(1)

template.display_name      # => "Rent"
template.frequency_text    # => "Monthly", "Weekly", "Biweekly", or "Yearly"
```

### Soft Delete (Deactivation)

```ruby
template = ExpenseTemplate.find(1)

# Deactivate a template (soft delete)
template.deactivate!
template.is_active?  # => false
template.active?      # => false

# Reactivate a template
template.activate!
template.is_active?  # => true
template.active?      # => true

# Check if template is active
if template.active?
  # Template is available for use
end
```

## Relationship with Expense

The `ExpenseTemplate` model serves as a template for creating `Expense records. Each expensebelongs to an expensetemplate and can inherit or override its properties. This design allows:

1. **Consistency**: Expense using the same template have consistent default type and savings status
2. **Reusability**: A single template can be used across multiple monthly budgets
3. **Flexibility**: Expense can override template name for specific months
4. **Centralized Management**: Changing a template's properties affects all expense using it (unless overridden)
5. **Organization**: Users can define their expensetemplates once and reuse them

The expenseuses the template's `name` by default (via the `name` method, which checks for override first, then falls back to `expense_template.name`) and tracks its own `allotted_amount` per monthly budget. The `spent_amount` is calculated from related payment records.

### Override Behavior

Expense can override template values:
- **name**: If `expense.name` is set, it overrides `expense_template.name`

**Note:** `frequency` and `due_date` always come from the template and cannot be overridden per expense. The expense inherits these values from its template.

When override fields are `NULL`, the expenseuses the template's values. This allows for both consistency (using templates) and flexibility (customizing per month).

### Active/Inactive Templates

- Only **active** templates are shown in dropdowns and used for auto-creation
- **Inactive** templates are hidden from normal views but preserved in the database
- Existing expense can still reference inactive templates (they remain valid)
- Admins can access inactive templates for viewing/editing
- Templates can be reactivated if needed

---

**Last Updated**: December 2025

