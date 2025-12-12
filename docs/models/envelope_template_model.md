# Envelope Template Model Documentation

## Overview

The `EnvelopeTemplate` model represents user-defined templates that can be reused across monthly budgets to create envelopes. Each template defines the type of spending (fixed vs variable), whether it's a savings pot, default amounts, and auto-creation behavior. Envelopes reference envelope templates to inherit their properties, but can override name, group_type, and is_savings on a per-month basis.

## Model Location

`app/models/envelope_template.rb`

## Schema

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | Primary Key | Auto-incrementing unique identifier |
| `user_id` | bigint | NOT NULL, Foreign Key | References the user who owns this template |
| `name` | string | NOT NULL | Template name (e.g., "Rent", "Groceries", "Emergency Fund") |
| `group_type` | integer | NOT NULL, Default: 1 | 0 = fixed (rent, Netflix), 1 = variable (food, fun) |
| `is_savings` | boolean | NOT NULL, Default: false | true = savings pot (emergency fund, vacation, etc.) |
| `default_amount` | decimal(12,2) | Nullable | Default amount to allocate when creating envelopes |
| `auto_create` | boolean | NOT NULL, Default: true | Automatically create envelope in monthly budgets |
| `is_active` | boolean | NOT NULL, Default: true | Whether the template is active (soft delete) |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Last update timestamp |

### Indexes

- **User ID + Name Index**: Composite unique index on `[user_id, name]` - ensures unique template names per user (only among active templates)
- **User ID + Group Type Index**: Composite index on `[user_id, group_type]` - optimized for finding templates by type
- **Is Active Index**: Index on `is_active` - optimized for filtering active/inactive templates

### Foreign Keys

- `envelope_templates.user_id` references `users.id` with `on_delete: :cascade`. If a user account is deleted (by admin), all their envelope templates are automatically deleted via database cascade.

## Associations

### Belongs To

- `belongs_to :user` - Each envelope template belongs to a user who owns it

### Has Many

- `has_many :envelopes, dependent: :destroy` - An envelope template can have many envelopes across different monthly budgets. When a template is hard deleted (by admin only), all associated envelopes are deleted. Soft delete (deactivation) preserves envelopes.

## Validations

### Presence Validations

- `validates :name, presence: true` - The template name must be present.

### Uniqueness Validations

- `validates :name, uniqueness: { scope: :user_id, conditions: -> { where(is_active: true) } }` - Template names must be unique per user among active templates. Different users can have templates with the same name. Inactive templates don't count toward uniqueness, allowing the same name to be reused after deactivation.

### Numericality Validations

- `validates :default_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true` - The default amount must be greater than or equal to 0 if provided, but can be nil.

## Enums

- `enum :group_type, { fixed: 0, variable: 1 }, default: :variable` - Defines the two group types:
  - `fixed` (0): Recurring bills that are consistent (rent, Netflix, insurance)
  - `variable` (1): Flexible spending that varies (food, fun, entertainment)

The enum automatically provides:
- `group_type` attribute with string values ("fixed", "variable")
- Boolean methods: `fixed?`, `variable?`
- Scopes: `EnvelopeTemplate.fixed`, `EnvelopeTemplate.variable`

## Default Scope

- `default_scope -> { order(:name) }` - All queries are ordered alphabetically by name by default. Use `.reorder()` to override this ordering when needed (e.g., `EnvelopeTemplate.active.reorder(created_at: :desc)`).

## Scopes

- `scope :active` - Returns only active templates (`is_active: true`)
- `scope :inactive` - Returns only inactive templates (`is_active: false`)
- `scope :fixed` - Returns only fixed envelope templates
- `scope :variable` - Returns only variable envelope templates
- `scope :savings` - Returns only savings templates (`is_savings: true`)
- `scope :non_savings` - Returns only non-savings templates (`is_savings: false`)
- `scope :auto_create` - Returns only templates with `auto_create: true`

**Note:** Most queries should use `.active` to only show active templates. The `active` scope should be chained with other scopes (e.g., `EnvelopeTemplate.active.fixed`). To override the default alphabetical ordering, use `.reorder()` (e.g., `EnvelopeTemplate.active.reorder(created_at: :desc)`).

## Instance Methods

- `display_name` - Returns a friendly display name. If it's a savings template, returns `"#{name} (Savings)"`, otherwise just the name.
  
- `group_type_text` - Returns a text description of the group type:
  - `"Fixed bill"` for fixed templates
  - `"Variable spending"` for variable templates

- `deactivate!` - Soft deletes the template by setting `is_active` to `false`. Preserves the template and all associated envelopes for historical purposes.

- `activate!` - Reactivates a deactivated template by setting `is_active` to `true`.

- `active?` - Returns `true` if the template is active, `false` otherwise. Alias for `is_active?`.

## Business Rules

1. **Unique Names Per User**: Each user can only have one template with a given name. Different users can have templates with the same name.

2. **Group Type Classification**: Templates are classified as either "fixed" (consistent recurring bills) or "variable" (flexible spending). This affects how envelopes are used in budgeting.

3. **Savings Pots**: Templates can be marked as savings pots, which are typically used for goals like emergency funds, vacations, or major purchases.

4. **Default Amounts**: Templates can have a default amount that will be used when automatically creating envelopes in monthly budgets.

5. **Auto-Create**: When `auto_create` is true, the system will automatically create envelopes from this template in monthly budgets using the `MonthlyBudget#auto_create_envelopes` method. Only active templates are used for auto-creation.

6. **Soft Delete (is_active)**: Templates use soft delete via the `is_active` field. When a template is "deleted", it's actually deactivated (`is_active: false`) rather than removed from the database. This preserves:
   - Historical data integrity
   - Existing envelopes that reference the template
   - Ability to reactivate templates if needed
   - No cascade deletion issues

7. **Active Templates Only**: Most queries should filter to active templates using `.active`. Inactive templates are hidden from normal views but can still be accessed by admins.

8. **Cascade Deletion**: 
   - **User Deletion**: When a user account is deleted (by admin), all their envelope templates are automatically deleted via database cascade (`on_delete: :cascade`).
   - **Template Hard Delete**: When an envelope template is actually destroyed (hard delete, not just deactivated), all associated envelopes are deleted via `dependent: :destroy`. **Note:** Only admins can perform hard deletes on templates. Regular users can only soft delete (deactivate) templates.

9. **Default Ordering**: All queries are ordered alphabetically by name by default. This provides consistent, user-friendly ordering in dropdowns and lists. Use `.reorder()` to override when needed (e.g., to show newest first).

## Usage Examples

### Creating an Envelope Template

```ruby
user = User.find(1)

# Create a fixed envelope template for rent
rent_template = EnvelopeTemplate.create!(
  user: user,
  name: "Rent",
  group_type: :fixed,
  is_savings: false,
  default_amount: 1200.00,
  auto_create: true
)

# Create a variable envelope template for groceries
groceries_template = EnvelopeTemplate.create!(
  user: user,
  name: "Groceries",
  group_type: :variable,
  is_savings: false,
  default_amount: 500.00,
  auto_create: true
)

# Create a savings template
emergency_fund = EnvelopeTemplate.create!(
  user: user,
  name: "Emergency Fund",
  group_type: :fixed,
  is_savings: true,
  default_amount: 300.00,
  auto_create: true
)
```

### Finding Templates

```ruby
user = User.find(1)

# Find all active fixed templates
fixed_templates = user.envelope_templates.active.fixed

# Find all active savings templates
savings_templates = user.envelope_templates.active.savings

# Find a specific active template
rent = user.envelope_templates.active.find_by(name: "Rent")

# Find inactive templates (admin use)
inactive_templates = user.envelope_templates.inactive
```

### Using with Envelopes

```ruby
template = EnvelopeTemplate.find(1)
monthly_budget = MonthlyBudget.find(1)

# Create an envelope using this template
envelope = Envelope.create!(
  monthly_budget: monthly_budget,
  envelope_template: template,
  # Name comes from the template (unless overridden)
  allotted_amount: template.default_amount || 0
)

# The envelope inherits group_type and is_savings from the template
envelope.group_type  # => "fixed" (from template, unless overridden)
envelope.is_savings? # => false (from template, unless overridden)

# Create an envelope with overrides
custom_envelope = Envelope.create!(
  monthly_budget: monthly_budget,
  envelope_template: template,
  name: "Custom Name",  # Override template name
  group_type: 1,        # Override to variable
  is_savings: true,     # Override to savings
  allotted_amount: 600.00
)
```

### Display Methods

```ruby
template = EnvelopeTemplate.find(1)

template.display_name      # => "Rent" or "Emergency Fund (Savings)"
template.group_type_text   # => "Fixed bill" or "Variable spending"
```

### Soft Delete (Deactivation)

```ruby
template = EnvelopeTemplate.find(1)

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

## Relationship with Envelopes

The `EnvelopeTemplate` model serves as a template for creating `Envelope` records. Each envelope belongs to an envelope template and can inherit or override its properties. This design allows:

1. **Consistency**: Envelopes using the same template have consistent default type and savings status
2. **Reusability**: A single template can be used across multiple monthly budgets
3. **Flexibility**: Envelopes can override template values (name, group_type, is_savings) for specific months
4. **Centralized Management**: Changing a template's properties affects all envelopes using it (unless overridden)
5. **Organization**: Users can define their envelope templates once and reuse them

The envelope uses the template's `name` by default (via the `name` method, which checks for override first, then falls back to `envelope_template.name`) and tracks its own `allotted_amount` per monthly budget. The `spent_amount` is calculated from related spending records.

### Override Behavior

Envelopes can override template values:
- **name**: If `envelopes.name` is set, it overrides `envelope_template.name`

**Note:** `group_type` and `is_savings` always come from the template and cannot be overridden per envelope.

When override fields are `NULL`, the envelope uses the template's values. This allows for both consistency (using templates) and flexibility (customizing per month).

### Active/Inactive Templates

- Only **active** templates are shown in dropdowns and used for auto-creation
- **Inactive** templates are hidden from normal views but preserved in the database
- Existing envelopes can still reference inactive templates (they remain valid)
- Admins can access inactive templates for viewing/editing
- Templates can be reactivated if needed

---

**Last Updated**: December 2025

