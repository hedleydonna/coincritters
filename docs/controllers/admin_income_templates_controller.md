# Admin::IncomeTemplatesController Documentation

## Overview

The `Admin::IncomeTemplatesController` provides read, update, and delete functionality for managing income template records in the admin interface. Income templates represent recurring income sources for users.

## Location

`app/controllers/admin/income_templates_controller.rb`

## Inheritance

- Inherits from `Admin::BaseController`
- Requires authentication and admin privileges

## Routes

All routes are namespaced under `/admin/income_templates`:

- **GET** `/admin/income_templates` - List all income templates (index)
- **GET** `/admin/income_templates/:id` - Show income template details
- **GET** `/admin/income_templates/:id/edit` - Show edit income template form
- **PATCH/PUT** `/admin/income_templates/:id` - Update an income template
- **DELETE** `/admin/income_templates/:id` - Delete an income template

**Note:** This controller does not provide `new` or `create` actions. Income templates are typically created through user-facing interfaces.

## Actions

### `index`

Lists all income template records with statistics.

**Instance Variables:**
- `@income_templates` - All income templates, ordered by creation date (newest first), includes `user` association
- `@total_income_templates` - Total count of all income template records
- `@active_income_templates` - Count of active income template records (uses `active` scope)
- `@auto_create_income_templates` - Count of income templates with `auto_create: true` (uses `auto_create` scope)

**Query Optimization:**
- Uses `includes(:user)` to eager load user associations and prevent N+1 queries

### `show`

Displays detailed information about a specific income template record.

**Instance Variables:**
- `@income_template` - The income template to display (set by `before_action :set_income_template`)

### `edit`

Shows the form to edit an existing income template record.

**Instance Variables:**
- `@income_template` - The income template to edit (set by `before_action :set_income_template`)

### `update`

Updates an existing income template record from form parameters.

**Success:**
- Redirects to `admin_income_template_path(@income_template)` with success notice: "Income template was successfully updated."

**Failure:**
- Re-renders the `edit` template with `:unprocessable_entity` status

### `destroy`

Deletes an income template record.

**Behavior:**
- Destroys the income template record
- Redirects to `admin_income_templates_path` with success notice: "Income template was successfully deleted."

## Callbacks

### `before_action :set_income_template`

Sets `@income_template` for `show`, `edit`, `update`, and `destroy` actions:

```ruby
def set_income_template
  @income_template = IncomeTemplate.find(params[:id])
end
```

## Strong Parameters

### `income_template_params`

Permits the following parameters:

- `name` - The name of the income source (string, required)
- `frequency` - How often the income is received (string, default: "monthly")
- `estimated_amount` - Estimated income amount (decimal, default: 0.0)
- `active` - Whether the income template is currently active (boolean, default: true)
- `user_id` - The user who owns this income template (required)
- `auto_create` - Whether to automatically create income events (boolean, default: false)
- `due_date` - Date when income is typically received (date, nullable, required if auto_create is true)
- `last_payment_to_next_month` - Whether to defer last payment of month to next month (boolean, default: false)

## Access Control

- Requires user authentication (`before_action :authenticate_user!` from `Admin::BaseController`)
- Requires admin privileges (`before_action :ensure_admin` from `Admin::BaseController`)

## Related Models

- **IncomeTemplate** - The model being managed
- **User** - Required association for income templates
- **IncomeEvent** - Income templates can have many income events (optional association)

## Views

- `app/views/admin/income_templates/index.html.erb` - List of all income templates
- `app/views/admin/income_templates/show.html.erb` - Income template details
- `app/views/admin/income_templates/edit.html.erb` - Edit income template form

## Usage Examples

### Updating an Income Template

```ruby
PATCH /admin/income_templates/1
{
  income_template: {
    name: "Updated Salary",
    estimated_amount: 5500.00,
    active: true,
    auto_create: true,
    due_date: "2025-12-01",
    last_payment_to_next_month: false
  }
}
```

---

**Last Updated**: December 2025

