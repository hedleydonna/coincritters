# IncomeTemplatesController Documentation

## Overview

The `IncomeTemplatesController` provides CRUD functionality for users to manage their income templates (income sources). Templates define recurring income that can be automatically created as income events in monthly budgets.

## Location

`app/controllers/income_templates_controller.rb`

## Inheritance

- Inherits from `ApplicationController`
- Requires authentication (`before_action :authenticate_user!`)

## Routes

All routes are under `/income_templates`:
- **GET** `/income_templates` - List all income templates (index)
- **GET** `/income_templates/new` - Show new template form
- **POST** `/income_templates` - Create a new template
- **GET** `/income_templates/:id/edit` - Show edit template form
- **PATCH/PUT** `/income_templates/:id` - Update a template
- **DELETE** `/income_templates/:id` - Deactivate a template (soft delete)
- **PATCH** `/income_templates/:id/reactivate` - Reactivate a deactivated template

## Actions

### `index`

Lists all active and inactive income templates for the current user.

**Instance Variables:**
- `@income_templates` - All active templates for the current user, ordered by name
- `@inactive_income_templates` - All inactive templates for the current user, ordered by name

**Behavior:**
- Shows active templates in the main list
- Shows inactive templates separately (can be reactivated)

### `new`

Shows the form to create a new income template.

**Instance Variables:**
- `@income_template` - New IncomeTemplate instance for the current user
- Defaults `frequency` to "monthly"
- Defaults `auto_create` to `false`

### `create`

Creates a new income template from form parameters.

**Success:**
- Redirects to `income_templates_path` with notice: "Income source created!"

**Failure:**
- Re-renders the `new` template with `:unprocessable_entity` status

### `edit`

Shows the form to edit an existing income template.

**Instance Variables:**
- `@income_template` - The template to edit (set by `before_action :set_income_template`)

### `update`

Updates an existing income template from form parameters.

**Success:**
- Redirects to `income_templates_path` with notice: "Income source updated!"

**Failure:**
- Re-renders the `edit` template with `:unprocessable_entity` status

### `destroy`

Soft deletes an income template by deactivating it (sets `active: false`).

**Behavior:**
- Updates `active` to `false` (soft delete)
- Preserves the template and all associated income events for historical purposes
- Redirects to `income_templates_path` with notice: "Income source turned off. It will stop creating events in new months."

### `reactivate`

Reactivates a deactivated income template (sets `active: true`).

**Behavior:**
- Updates `active` to `true`
- Redirects to `income_templates_path` with notice: "Income source turned back on!"

## Callbacks

### `before_action :set_income_template`

Sets `@income_template` for `edit`, `update`, `destroy`, and `reactivate` actions:

```ruby
def set_income_template
  @income_template = current_user.income_templates.find(params[:id])
end
```

- Only finds templates belonging to the current user
- Raises ActiveRecord::RecordNotFound if template doesn't belong to user

## Strong Parameters

### `income_template_params`

Permits the following parameters:

- `name` - The template name (required, unique per user)
- `frequency` - Income frequency: "weekly", "bi_weekly", "monthly", or "irregular"
- `due_date` - Date when income is typically received (required if `auto_create: true`)
- `estimated_amount` - Estimated amount for this income source (decimal, required, >= 0)
- `auto_create` - Whether to automatically create income events from this template when creating monthly budgets (boolean)
- `active` - Whether the template is active (boolean)
- `last_payment_to_next_month` - Whether the last payment of the month should be deferred to next month (boolean)

## Access Control

- Requires user authentication (`before_action :authenticate_user!`)
- Users can only manage their own income templates
- Template lookup is scoped to current_user (prevents access to other users' templates)

## Related Models

- **IncomeTemplate** - The model being managed
- **User** - Templates belong to users
- **IncomeEvent** - Templates have many income events (created in monthly budgets)

## Views

- `app/views/income_templates/index.html.erb` - List of all templates (active and inactive)
- `app/views/income_templates/new.html.erb` - New template form
- `app/views/income_templates/edit.html.erb` - Edit template form

## Usage Examples

### Creating an Income Template

```ruby
POST /income_templates
{
  income_template: {
    name: "Monthly Salary",
    frequency: "monthly",
    due_date: 1,  # Day of month
    estimated_amount: 5000.00,
    auto_create: true,
    last_payment_to_next_month: false
  }
}
```

### Updating an Income Template

```ruby
PATCH /income_templates/1
{
  income_template: {
    name: "Monthly Salary",
    frequency: "monthly",
    due_date: 1,
    estimated_amount: 5500.00,
    auto_create: true,
    last_payment_to_next_month: true
  }
}
```

### Deactivating a Template

```ruby
DELETE /income_templates/1
# Soft deletes by setting active: false
```

### Reactivating a Template

```ruby
PATCH /income_templates/1/reactivate
# Sets active: true
```

## Key Features

1. **Soft Delete**: Templates are deactivated (not deleted) to preserve historical data
2. **Auto-Create**: Templates with `auto_create: true` automatically create income events in new monthly budgets
3. **User Scoped**: All operations are scoped to the current user
4. **Active/Inactive Separation**: Active and inactive templates are shown separately in the index
5. **Deferral Support**: Templates can have `last_payment_to_next_month` to defer last payment of month

---

**Last Updated**: December 2025

