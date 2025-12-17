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
- **GET** `/expense_templates?return_to=expenses` - List templates with return navigation context
- **GET** `/expense_templates/new` - Show new template form
- **GET** `/expense_templates/new?return_to=expenses` - Show new template form with return navigation
- **POST** `/expense_templates` - Create a new template
- **GET** `/expense_templates/:id/edit` - Show edit template form
- **GET** `/expense_templates/:id/edit?return_to=expenses` - Show edit template form with return navigation
- **PATCH/PUT** `/expense_templates/:id` - Update a template
- **DELETE** `/expense_templates/:id` - Soft delete a template (sets `deleted_at`)
- **PATCH** `/expense_templates/:id/reactivate` - Restore a deleted template

## Actions

### `index`

Lists all active expense templates for the current user. Deleted templates are hidden from normal views.

**Instance Variables:**
- `@templates` - All active (non-deleted) templates for the current user, ordered by name
- `@return_to` - Navigation context parameter ('expenses', 'settings', or nil)

**Behavior:**
- Shows only active templates (where `deleted_at IS NULL`)
- Deleted templates are not shown in the main list
- Supports `return_to` parameter for context-aware navigation

### `new`

Shows the form to create a new expense template.

**Instance Variables:**
- `@template` - New, unsaved ExpenseTemplate instance for the current user
- `@return_to` - Navigation context parameter for redirect after creation

### `create`

Creates a new expense template from form parameters.

**Success:**
- Always redirects to `expense_templates_path(return_to: params[:return_to])` with notice: "Spending item created!"
- Preserves `return_to` parameter for navigation context

**Failure:**
- Re-renders the `new` template with `:unprocessable_entity` status

### `edit`

Shows the form to edit an existing expense template.

**Instance Variables:**
- `@template` - The template to edit (set by `before_action :set_template`)
- `@return_to` - Navigation context parameter for redirect after update

### `update`

Updates an existing expense template from form parameters.

**Success:**
- If `return_to == 'expenses'`, redirects to `expenses_path`
- Otherwise, redirects to `expense_templates_path(return_to: params[:return_to])` with notice: "Branch updated!"

**Failure:**
- Re-renders the `edit` template with `:unprocessable_entity` status

### `destroy`

Soft deletes an expense template by setting `deleted_at` timestamp.

**Behavior:**
- Uses `soft_delete!` method (sets `deleted_at` to current time)
- Preserves the template and all associated expenses for historical purposes
- Always redirects to `expense_templates_path(return_to: params[:return_to])` with notice: "Spending item deleted. It will stop appearing in new months."
- Preserves `return_to` parameter for navigation context
- Uses Turbo confirmation dialog with strong warning about data loss

### `reactivate`

Restores a deleted expense template by clearing `deleted_at`.

**Behavior:**
- Uses `restore!` method (sets `deleted_at` to `nil`)
- Uses `with_deleted` scope to find the template
- If `return_to == 'expenses'`, redirects to `expenses_path`
- Otherwise, redirects to `expense_templates_path(return_to: params[:return_to])` with notice: "Spending item restored!"

## Callbacks

### `before_action :set_template`

Sets `@template` for `edit`, `update`, and `destroy` actions:

```ruby
def set_template
  @template = current_user.expense_templates.find(params[:id])
end
```

- Only finds active (non-deleted) templates belonging to the current user
- Raises ActiveRecord::RecordNotFound if template doesn't belong to user or is deleted

### `before_action :set_deleted_template`

Sets `@template` for `reactivate` action:

```ruby
def set_deleted_template
  @template = current_user.expense_templates.with_deleted.find(params[:id])
end
```

- Uses `with_deleted` scope to find deleted templates
- Only finds templates belonging to the current user

## Strong Parameters

### `template_params`

Permits the following parameters:

- `name` - The template name (required, unique per user among active templates)
- `frequency` - Expense frequency: "monthly", "weekly", "biweekly", or "yearly" (default: "monthly")
- `due_date` - Optional due date for the expense (date)
- `default_amount` - Default amount to allocate when creating expenses from this template (decimal)
- `auto_create` - Whether to automatically create expenses from this template when creating monthly budgets (boolean, default: true)

**Note:** `deleted_at` is not permitted - users can only soft delete via the destroy action.

## Access Control

- Requires user authentication (`before_action :authenticate_user!`)
- Users can only manage their own expense templates
- Template lookup is scoped to current_user (prevents access to other users' templates)

## Related Models

- **ExpenseTemplate** - The model being managed
- **User** - Templates belong to users
- **Expense** - Templates have many expenses (created in monthly budgets)

## Views

- `app/views/expense_templates/index.html.erb` - List of active templates with context-aware navigation
  - Page title: "Set Up Your Spending"
  - Icon-based action buttons (Edit, Delete) with tooltips
  - Back arrow navigation based on `return_to` parameter
  - Uses Turbo for form submissions and delete actions
- `app/views/expense_templates/new.html.erb` - New template form
  - Page title: "New Spending Item"
  - Context-aware back navigation
- `app/views/expense_templates/edit.html.erb` - Edit template form
  - Page title: "Edit Spending Item"
  - Context-aware back navigation
- `app/views/expense_templates/_form.html.erb` - Shared form partial
  - Uses Turbo (no `local: true`)
  - Preserves `return_to` parameter via hidden field

## Usage Examples

### Creating an Expense Template

```ruby
POST /expense_templates?return_to=expenses
{
  expense_template: {
    name: "Groceries",
    frequency: "monthly",
    default_amount: 500.00,
    auto_create: true
  },
  return_to: "expenses"
}
# Redirects to expense_templates_path(return_to: "expenses")
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

### Soft Deleting a Template

```ruby
DELETE /expense_templates/1?return_to=expenses
# Soft deletes by setting deleted_at timestamp
# Redirects to expense_templates_path(return_to: "expenses")
```

### Restoring a Deleted Template

```ruby
PATCH /expense_templates/1/reactivate?return_to=expenses
# Clears deleted_at (sets to nil)
# Redirects based on return_to parameter
```

## Key Features

1. **Soft Delete with `deleted_at`**: Templates are soft deleted using `deleted_at` timestamp to preserve historical data
2. **Context-Aware Navigation**: Supports `return_to` parameter for returning to originating page (Spending, Dashboard, or Settings)
3. **Auto-Create**: Templates with `auto_create: true` automatically create expenses in new monthly budgets
4. **User Scoped**: All operations are scoped to the current user
5. **Turbo Integration**: Forms and delete actions use Turbo for seamless interactions
6. **Icon-Based UI**: Action buttons use icons with tooltips for better UX
7. **Filtered Views**: Expenses from deleted templates are automatically filtered out from the spending list

## Terminology

- **Spending Item**: User-facing term for expense template
- **Set Up Your Spending**: Page title for the expense templates index
- **New Spending Item**: Form title for creating a new template
- **Edit Spending Item**: Form title for editing a template

---

**Last Updated**: January 2026

