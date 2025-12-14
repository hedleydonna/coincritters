# Admin::ExpenseTemplatesController Documentation

## Overview

The `Admin::ExpenseTemplatesController` provides full CRUD (Create, Read, Update, Delete) functionality for managing expensetemplates in the admin interface. Expensetemplates serve as reusable configurations for creating expense.

## Location

`app/controllers/admin/expense_templates_controller.rb`

## Inheritance

- Inherits from `Admin::BaseController`
- Requires authentication and admin privileges

## Routes

All routes are namespaced under `/admin/expense_templates`:

- **GET** `/admin/expense_templates` - List all expensetemplates (index)
- **GET** `/admin/expense_templates/new` - Show new template form
- **POST** `/admin/expense_templates` - Create a new template
- **GET** `/admin/expense_templates/:id` - Show template details
- **GET** `/admin/expense_templates/:id/edit` - Show edit template form
- **PATCH/PUT** `/admin/expense_templates/:id` - Update a template
- **DELETE** `/admin/expense_templates/:id` - Delete a template

## Actions

### `index`

Lists all active expensetemplates with statistics.

**Instance Variables:**
- `@expense_templates` - All active templates, ordered by creation date (newest first), includes `user` association
- `@total_templates` - Total count of all active templates
- `@fixed_templates` - Count of active fixed templates
- `@variable_templates` - Count of active variable templates
- `@savings_templates` - Count of active savings templates

**Query Optimization:**
- Uses `includes(:user)` to eager load user associations and prevent N+1 queries
- Uses `.active` scope to only show active templates (inactive templates are hidden)

### `show`

Displays detailed information about a specific expensetemplate.

**Instance Variables:**
- `@expense_template` - The template to display (set by `before_action :set_expense_template`)

### `new`

Shows the form to create a new expensetemplate.

**Instance Variables:**
- `@expense_template` - A new, unsaved `ExpenseTemplate` instance
- `@users` - All users, ordered by email (for user selection dropdown)

### `create`

Creates a new expensetemplate from form parameters.

**Success:**
- Redirects to `admin_expense_template_path(@expense_template)` with success notice: "Expensetemplate was successfully created."

**Failure:**
- Re-renders the `new` template with `:unprocessable_entity` status
- Re-sets `@users` for the form

### `edit`

Shows the form to edit an existing expensetemplate.

**Instance Variables:**
- `@expense_template` - The template to edit (set by `before_action :set_expense_template`)
- `@users` - All users, ordered by email (for user selection dropdown)

### `update`

Updates an existing expensetemplate from form parameters.

**Success:**
- Redirects to `admin_expense_template_path(@expense_template)` with success notice: "Expensetemplate was successfully updated."

**Failure:**
- Re-renders the `edit` template with `:unprocessable_entity` status
- Re-sets `@users` for the form

### `destroy`

Soft deletes an expensetemplate (deactivates it).

**Behavior:**
- Sets `is_active` to `false` instead of actually deleting the template (soft delete)
- Preserves the template and all associated expense for historical purposes
- Template is hidden from normal views but can still be accessed by admins
- Redirects to `admin_expense_templates_path` with success notice: "Expensetemplate was successfully deleted."

## Callbacks

### `before_action :set_expense_template`

Sets `@expense_template` for `show`, `edit`, `update`, and `destroy` actions:

```ruby
  def set_expense_template
    # Finds templates even if they're inactive (for admin access to view/edit)
    @expense_template = ExpenseTemplate.find(params[:id])
  end
```

## Strong Parameters

### `expense_template_params`

Permits the following parameters:

- `user_id` - The user who owns this template
- `name` - The template name (required, unique per user)
- `group_type` - The group type (0=fixed, 1=variable, default: variable)
- `is_savings` - Whether this is a savings template (boolean, default: false)
- `default_amount` - Default amount to use when creating expense from this template (decimal, default: 0.0)
- `auto_create` - Whether to automatically create expense from this template when creating monthly budgets (boolean, default: true)
- `is_active` - Whether the template is active (boolean, default: true). Inactive templates are soft-deleted (hidden but preserved).

## Access Control

- Requires user authentication (`before_action :authenticate_user!` from `Admin::BaseController`)
- Requires admin privileges (`before_action :ensure_admin` from `Admin::BaseController`)

## Related Models

- **ExpenseTemplate** - The model being managed
- **User** - Required association for templates
- **Expense* - Templates have many expense. When a template is soft-deleted (deactivated), associated expense remain intact and can still reference the inactive template.

## Views

- `app/views/admin/expense_templates/index.html.erb` - List of all templates
- `app/views/admin/expense_templates/show.html.erb` - Template details
- `app/views/admin/expense_templates/new.html.erb` - New template form
- `app/views/admin/expense_templates/edit.html.erb` - Edit template form

## Usage Examples

### Creating an ExpenseTemplate

```ruby
POST /admin/expense_templates
{
  expense_template: {
    user_id: 1,
    name: "Groceries",
    group_type: 1,  # variable
    is_savings: false,
    default_amount: 500.00,
    auto_create: true
  }
}
```

### Creating a Fixed Bill Template

```ruby
POST /admin/expense_templates
{
  expense_template: {
    user_id: 1,
    name: "Rent",
    group_type: 0,  # fixed
    is_savings: false,
    default_amount: 1200.00,
    auto_create: true
  }
}
```

### Creating a Savings Template

```ruby
POST /admin/expense_templates
{
  expense_template: {
    user_id: 1,
    name: "Emergency Fund",
    group_type: 0,  # fixed
    is_savings: true,
    default_amount: 300.00,
    auto_create: false
  }
}
```

---

**Last Updated**: December 2025

