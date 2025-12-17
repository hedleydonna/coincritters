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
- **GET** `/income_templates?return_to=income_events` - List templates with return navigation context
- **GET** `/income_templates/new` - Show new template form
- **GET** `/income_templates/new?return_to=income_events` - Show new template form with return navigation
- **POST** `/income_templates` - Create a new template
- **GET** `/income_templates/:id/edit` - Show edit template form
- **GET** `/income_templates/:id/edit?return_to=income_events` - Show edit template form with return navigation
- **PATCH/PUT** `/income_templates/:id` - Update a template
- **DELETE** `/income_templates/:id` - Soft delete a template (sets `deleted_at`)
- **PATCH** `/income_templates/:id/reactivate` - Restore a deleted template

## Actions

### `index`

Lists all active income templates for the current user. Deleted templates are hidden from normal views.

**Instance Variables:**
- `@income_templates` - All active (non-deleted) templates for the current user, ordered by name
- `@return_to` - Navigation context parameter ('income_events', 'settings', or nil)

**Behavior:**
- Shows only active templates (where `deleted_at IS NULL`)
- Deleted templates are not shown in the main list
- Supports `return_to` parameter for context-aware navigation

### `new`

Shows the form to create a new income template.

**Instance Variables:**
- `@income_template` - New IncomeTemplate instance for the current user
- `@return_to` - Navigation context parameter for redirect after creation
- Defaults `frequency` to "monthly"
- Defaults `auto_create` to `false`

### `create`

Creates a new income template from form parameters.

**Success:**
- Always redirects to `income_templates_path(return_to: params[:return_to])` with notice: "Money in source created!"
- Preserves `return_to` parameter for navigation context

**Failure:**
- Re-renders the `new` template with `:unprocessable_entity` status

### `edit`

Shows the form to edit an existing income template.

**Instance Variables:**
- `@income_template` - The template to edit (set by `before_action :set_income_template`)
- `@return_to` - Navigation context parameter for redirect after update

### `update`

Updates an existing income template from form parameters.

**Success:**
- If `return_to == 'income_events'`, redirects to `income_events_path`
- Otherwise, redirects to `income_templates_path(return_to: params[:return_to])` with notice: "Income source updated!"

**Failure:**
- Re-renders the `edit` template with `:unprocessable_entity` status

### `destroy`

Soft deletes an income template by setting `deleted_at` timestamp.

**Behavior:**
- Uses `soft_delete!` method (sets `deleted_at` to current time)
- Preserves the template and all associated income events for historical purposes
- Always redirects to `income_templates_path(return_to: params[:return_to])` with notice: "Money in source deleted. It will stop creating events in new months."
- Preserves `return_to` parameter for navigation context
- Uses Turbo confirmation dialog with strong warning about data loss

### `reactivate`

Restores a deleted income template by clearing `deleted_at`.

**Behavior:**
- Uses `restore!` method (sets `deleted_at` to `nil`)
- Uses `with_deleted` scope to find the template
- If `return_to == 'income_events'`, redirects to `income_events_path`
- Otherwise, redirects to `income_templates_path(return_to: params[:return_to])` with notice: "Money in source restored!"

## Callbacks

### `before_action :set_income_template`

Sets `@income_template` for `edit`, `update`, and `destroy` actions:

```ruby
def set_income_template
  @income_template = current_user.income_templates.find(params[:id])
end
```

- Only finds active (non-deleted) templates belonging to the current user
- Raises ActiveRecord::RecordNotFound if template doesn't belong to user or is deleted

### `before_action :set_deleted_income_template`

Sets `@income_template` for `reactivate` action:

```ruby
def set_deleted_income_template
  @income_template = current_user.income_templates.with_deleted.find(params[:id])
end
```

- Uses `with_deleted` scope to find deleted templates
- Only finds templates belonging to the current user

## Strong Parameters

### `income_template_params`

Permits the following parameters:

- `name` - The template name (required, unique per user among active templates)
- `frequency` - Income frequency: "weekly", "bi_weekly", "monthly", or "irregular"
- `due_date` - Date when income is typically received (required if `auto_create: true`)
- `estimated_amount` - Estimated amount for this income source (decimal, required, >= 0)
- `auto_create` - Whether to automatically create income events from this template when creating monthly budgets (boolean)
- `active` - Whether the template is active (boolean, legacy field - not used for soft deletion)
- `last_payment_to_next_month` - Whether the last payment of the month should be deferred to next month (boolean)

**Note:** `deleted_at` is not permitted - users can only soft delete via the destroy action.

## Access Control

- Requires user authentication (`before_action :authenticate_user!`)
- Users can only manage their own income templates
- Template lookup is scoped to current_user (prevents access to other users' templates)

## Related Models

- **IncomeTemplate** - The model being managed
- **User** - Templates belong to users
- **IncomeEvent** - Templates have many income events (created in monthly budgets)

## Views

- `app/views/income_templates/index.html.erb` - List of active templates with context-aware navigation
  - Page title: "Manage Income Sources"
  - Icon-based action buttons (Edit, Delete) with tooltips
  - Back arrow navigation based on `return_to` parameter
  - Uses Turbo for form submissions and delete actions
- `app/views/income_templates/new.html.erb` - New template form
  - Page title: "New Income Source"
  - Context-aware back navigation with tooltip
- `app/views/income_templates/edit.html.erb` - Edit template form
  - Page title: "Edit Income Source"
  - Context-aware back navigation with tooltip
- `app/views/income_templates/_form.html.erb` - Shared form partial
  - Uses Turbo (no `local: true`)
  - Preserves `return_to` parameter via hidden field

## Usage Examples

### Creating an Income Template

```ruby
POST /income_templates?return_to=income_events
{
  income_template: {
    name: "Monthly Salary",
    frequency: "monthly",
    due_date: Date.today,
    estimated_amount: 5000.00,
    auto_create: true,
    last_payment_to_next_month: false
  },
  return_to: "income_events"
}
# Redirects to income_templates_path(return_to: "income_events")
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

### Soft Deleting a Template

```ruby
DELETE /income_templates/1?return_to=income_events
# Soft deletes by setting deleted_at timestamp
# Redirects to income_templates_path(return_to: "income_events")
```

### Restoring a Deleted Template

```ruby
PATCH /income_templates/1/reactivate?return_to=income_events
# Clears deleted_at (sets to nil)
# Redirects based on return_to parameter
```

## Key Features

1. **Soft Delete with `deleted_at`**: Templates are soft deleted using `deleted_at` timestamp to preserve historical data
2. **Context-Aware Navigation**: Supports `return_to` parameter for returning to originating page (Money In, Dashboard, or Settings)
3. **Auto-Create**: Templates with `auto_create: true` automatically create income events in new monthly budgets
4. **User Scoped**: All operations are scoped to the current user
5. **Turbo Integration**: Forms and delete actions use Turbo for seamless interactions
6. **Icon-Based UI**: Action buttons use icons with tooltips for better UX
7. **Filtered Views**: Income events from deleted templates are automatically filtered out from the money-in list
8. **Deferral Support**: Templates can have `last_payment_to_next_month` to defer last payment of month

## Terminology

- **Income Source**: User-facing term for income template
- **Manage Income Sources**: Page title for the income templates index
- **New Income Source**: Form title for creating a new template
- **Edit Income Source**: Form title for editing a template

---

**Last Updated**: January 2026

