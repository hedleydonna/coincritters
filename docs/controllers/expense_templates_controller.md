# ExpenseTemplatesController Documentation

## Overview

The `ExpenseTemplatesController` provides CRUD functionality for users to manage their expense templates (also called "branches"). Templates define recurring expenses that can be automatically created in monthly budgets.

## Location

`app/controllers/expense_templates_controller.rb`

## Inheritance

- Inherits from `ApplicationController`
- Requires authentication (`before_action :authenticate_user!`)

## Routes

All routes are under `/expense_templates`:
- **GET** `/expense_templates` - List all expense templates (index)
- **GET** `/expense_templates/new` - Show new template form
- **POST** `/expense_templates` - Create a new template
- **GET** `/expense_templates/:id/edit` - Show edit template form
- **PATCH/PUT** `/expense_templates/:id` - Update a template
- **DELETE** `/expense_templates/:id` - Deactivate a template (soft delete)
- **PATCH** `/expense_templates/:id/reactivate` - Reactivate a deactivated template

## Actions

### `index`

Lists all active and inactive expense templates for the current user.

**Instance Variables:**
- `@templates` - All active templates for the current user, ordered by name
- `@inactive_templates` - All inactive templates for the current user, ordered by name

**Behavior:**
- Shows active templates in the main list
- Shows inactive templates separately (can be reactivated)

### `new`

Shows the form to create a new expense template.

**Instance Variables:**
- `@template` - New, unsaved ExpenseTemplate instance for the current user

### `create`

Creates a new expense template from form parameters.

**Success:**
- Redirects to `expense_templates_path` with notice: "Branch created!"

**Failure:**
- Re-renders the `new` template with `:unprocessable_entity` status

### `edit`

Shows the form to edit an existing expense template.

**Instance Variables:**
- `@template` - The template to edit (set by `before_action :set_template`)

### `update`

Updates an existing expense template from form parameters.

**Success:**
- Redirects to `expense_templates_path` with notice: "Branch updated!"

**Failure:**
- Re-renders the `edit` template with `:unprocessable_entity` status

### `destroy`

Soft deletes an expense template by deactivating it (sets `is_active: false`).

**Behavior:**
- Uses `deactivate!` method (soft delete)
- Preserves the template and all associated expenses for historical purposes
- Redirects to `expense_templates_path` with notice: "Branch turned off. It will stop appearing in new months."

### `reactivate`

Reactivates a deactivated expense template (sets `is_active: true`).

**Behavior:**
- Uses `activate!` method
- Redirects to `expense_templates_path` with notice: "Branch turned back on!"

## Callbacks

### `before_action :set_template`

Sets `@template` for `edit`, `update`, `destroy`, and `reactivate` actions:

```ruby
def set_template
  @template = current_user.expense_templates.find(params[:id])
end
```

- Only finds templates belonging to the current user
- Raises ActiveRecord::RecordNotFound if template doesn't belong to user

## Strong Parameters

### `template_params`

Permits the following parameters:

- `name` - The template name (required, unique per user among active templates)
- `frequency` - Expense frequency: "monthly", "weekly", "biweekly", or "yearly" (default: "monthly")
- `due_date` - Optional due date for the expense (date)
- `default_amount` - Default amount to allocate when creating expenses from this template (decimal)
- `auto_create` - Whether to automatically create expenses from this template when creating monthly budgets (boolean, default: true)

**Note:** `is_active` is not permitted - users can only soft delete via the destroy action.

## Access Control

- Requires user authentication (`before_action :authenticate_user!`)
- Users can only manage their own expense templates
- Template lookup is scoped to current_user (prevents access to other users' templates)

## Related Models

- **ExpenseTemplate** - The model being managed
- **User** - Templates belong to users
- **Expense** - Templates have many expenses (created in monthly budgets)

## Views

- `app/views/expense_templates/index.html.erb` - List of all templates (active and inactive)
- `app/views/expense_templates/new.html.erb` - New template form
- `app/views/expense_templates/edit.html.erb` - Edit template form
- `app/views/expense_templates/_form.html.erb` - Shared form partial

## Usage Examples

### Creating an Expense Template

```ruby
POST /expense_templates
{
  expense_template: {
    name: "Groceries",
    frequency: "monthly",
    default_amount: 500.00,
    auto_create: true
  }
}
```

### Updating an Expense Template

```ruby
PATCH /expense_templates/1
{
  expense_template: {
    name: "Groceries",
    frequency: "weekly",
    default_amount: 600.00,
    auto_create: true
  }
}
```

### Deactivating a Template

```ruby
DELETE /expense_templates/1
# Soft deletes by setting is_active: false
```

### Reactivating a Template

```ruby
PATCH /expense_templates/1/reactivate
# Sets is_active: true
```

## Key Features

1. **Soft Delete**: Templates are deactivated (not deleted) to preserve historical data
2. **Auto-Create**: Templates with `auto_create: true` automatically create expenses in new monthly budgets
3. **User Scoped**: All operations are scoped to the current user
4. **Active/Inactive Separation**: Active and inactive templates are shown separately in the index

---

**Last Updated**: December 2025

