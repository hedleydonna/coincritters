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
| `deleted_at` | datetime | Nullable | Timestamp when template was soft deleted (NULL = active) |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Last update timestamp |

### Indexes

- **User ID + Name Index**: Composite index on `[user_id, name]` - NOT unique (allows reusing names after deletion)
- **Deleted At Index**: Index on `deleted_at` - optimized for filtering active/deleted templates

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

- `validates :name, uniqueness: { scope: :user_id, conditions: -> { where(deleted_at: nil) } }` - Template names must be unique per user among active templates. Different users can have templates with the same name. Deleted templates don't count toward uniqueness, allowing the same name to be reused after deletion.

### Numericality Validations

- `validates :default_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true` - The default amount must be greater than or equal to 0 if provided, but can be nil.

### Inclusion Validations

- `validates :frequency, inclusion: { in: %w[monthly weekly biweekly yearly] }` - The frequency must be one of the valid values: "monthly", "weekly", "biweekly", or "yearly". Defaults to "monthly" if not specified.

## Default Scope

- `default_scope -> { where(deleted_at: nil).order(:name) }` - All queries exclude deleted templates and are ordered alphabetically by name by default. Use `.with_deleted` or `.unscoped` to access deleted templates. Use `.reorder()` to override this ordering when needed (e.g., `ExpenseTemplate.active.reorder(created_at: :desc)`).

## Scopes

- `scope :active` - Returns only active templates (`deleted_at IS NULL`) - redundant with default_scope but explicit
- `scope :deleted` - Returns only deleted templates (`deleted_at IS NOT NULL`) - requires `unscope(where: :deleted_at)` first
- `scope :with_deleted` - Removes the `deleted_at` filter from default_scope, allowing access to all templates including deleted ones
- `scope :auto_create` - Returns only templates with `auto_create: true`
- `scope :by_frequency` - Returns templates with a specific frequency (e.g., `ExpenseTemplate.by_frequency("monthly")`)

**Note:** The default scope already filters to active templates, so `.active` is redundant but explicit. To access deleted templates, use `.with_deleted` or `.unscoped`. To override the default alphabetical ordering, use `.reorder()` (e.g., `ExpenseTemplate.reorder(created_at: :desc)`).

## Instance Methods

- `display_name` - Returns the template name (same as `name`).
  
- `frequency_text` - Returns a human-readable text description of the frequency:
  - `"Monthly"` for monthly templates
  - `"Weekly"` for weekly templates
  - `"Biweekly"` for biweekly templates
  - `"Yearly"` for yearly templates
  - Defaults to `"Monthly"` if frequency is not set

- `soft_delete!` - Soft deletes the template by setting `deleted_at` to current time. Preserves the template and all associated expense for historical purposes.

- `restore!` - Restores a deleted template by setting `deleted_at` to `nil`.

- `deleted?` - Returns `true` if the template is deleted (`deleted_at` is present), `false` otherwise.

- `active?` - Returns `true` if the template is active (`deleted_at` is `nil`), `false` otherwise. Alias for checking if `deleted_at` is `nil`.

## Business Rules

1. **Unique Names Per User**: Each user can only have one template with a given name. Different users can have templates with the same name.

2. **Frequency**: Templates specify how often the expense occurs (monthly, weekly, biweekly, or yearly). This helps users understand the payment cadence.

3. **Due Dates**: Templates can optionally specify a due date, which helps users track when payments are typically due.

4. **Default Amounts**: Templates can have a default amount that will be used when automatically creating expense in monthly budgets.

5. **Auto-Create**: When `auto_create` is true, the system will automatically create expense from this template in monthly budgets using the `MonthlyBudget#auto_create_expenses` method. Expenses are automatically created:
   - When a new monthly budget is created (current or next month)
   - When viewing the expenses page (regenerates expenses for current and next month)
   - This ensures newly created templates with `auto_create: true` immediately appear in the spending list
   - Only active templates are used for auto-creation
   - Skips templates that already have an expense in that budget

6. **Soft Delete (deleted_at)**: Templates use soft delete via the `deleted_at` timestamp field. When a template is "deleted", it's actually marked with a timestamp (`deleted_at` is set) rather than removed from the database. This preserves:
   - Historical data integrity
   - Existing expense that reference the template
   - Ability to restore templates if needed
   - No cascade deletion issues
   - Historical reporting can still access deleted templates

7. **Active Templates Only**: The default scope automatically filters to active templates (where `deleted_at IS NULL`). Deleted templates are hidden from normal views but can be accessed using `.with_deleted` or `.unscoped`.

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

### Soft Delete

```ruby
template = ExpenseTemplate.find(1)

# Soft delete a template
template.soft_delete!
template.deleted?  # => true
template.active?   # => false
template.deleted_at  # => 2026-01-15 10:30:00 UTC (timestamp)

# Restore a deleted template
template.restore!
template.deleted?  # => false
template.active?   # => true
template.deleted_at  # => nil

# Check if template is active
if template.active?
  # Template is available for use
end

# Access deleted templates
deleted_templates = ExpenseTemplate.with_deleted.deleted
# or
all_templates = ExpenseTemplate.with_deleted
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

### Active/Deleted Templates

- Only **active** templates (where `deleted_at IS NULL`) are shown in dropdowns and used for auto-creation
- **Deleted** templates are hidden from normal views but preserved in the database
- Existing expense can still reference deleted templates (they remain valid)
- Deleted templates can be accessed using `.with_deleted` or `.unscoped` scopes
- Templates can be restored using `restore!` method
- Expenses from deleted templates are automatically filtered out from the spending list

### Auto-Creation Behavior

When an expense template has `auto_create: true` and `deleted_at IS NULL`:
- Expenses are automatically created when viewing the expenses/spending page
- Expenses are created for both current and next month budgets
- The system checks for existing expenses and skips templates that already have an expense in that budget
- Newly created templates with `auto_create: true` will immediately appear in the spending list after visiting the expenses page
- The expense's `allotted_amount` is set from the template's `default_amount` (or 0.0 if not set)

---

**Last Updated**: January 2026

