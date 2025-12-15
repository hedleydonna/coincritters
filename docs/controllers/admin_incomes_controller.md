# Admin::IncomesController Documentation

## Overview

The `Admin::IncomesController` provides read, update, and delete functionality for managing income records in the admin interface. Income records represent recurring income sources for users.

## Location

`app/controllers/admin/incomes_controller.rb`

## Inheritance

- Inherits from `Admin::BaseController`
- Requires authentication and admin privileges

## Routes

All routes are namespaced under `/admin/incomes`:

- **GET** `/admin/incomes` - List all incomes (index)
- **GET** `/admin/incomes/:id` - Show income details
- **GET** `/admin/incomes/:id/edit` - Show edit income form
- **PATCH/PUT** `/admin/incomes/:id` - Update an income
- **DELETE** `/admin/incomes/:id` - Delete an income

**Note:** This controller does not provide `new` or `create` actions. Incomes are typically created through other means (user registration, income events, etc.).

## Actions

### `index`

Lists all income records with statistics.

**Instance Variables:**
- `@incomes` - All incomes, ordered by creation date (newest first), includes `user` association
- `@total_incomes` - Total count of all income records
- `@active_incomes` - Count of active income records (uses `active` scope)
- `@auto_create_incomes` - Count of incomes with `auto_create: true` (uses `auto_create` scope)

**Query Optimization:**
- Uses `includes(:user)` to eager load user associations and prevent N+1 queries

### `show`

Displays detailed information about a specific income record.

**Instance Variables:**
- `@income` - The income to display (set by `before_action :set_income`)

### `edit`

Shows the form to edit an existing income record.

**Instance Variables:**
- `@income` - The income to edit (set by `before_action :set_income`)

### `update`

Updates an existing income record from form parameters.

**Success:**
- Redirects to `admin_income_path(@income)` with success notice: "Income was successfully updated."

**Failure:**
- Re-renders the `edit` template with `:unprocessable_entity` status

### `destroy`

Deletes an income record.

**Behavior:**
- Destroys the income record
- Redirects to `admin_incomes_path` with success notice: "Income was successfully deleted."

## Callbacks

### `before_action :set_income`

Sets `@income` for `show`, `edit`, `update`, and `destroy` actions:

```ruby
def set_income
  @income = Income.find(params[:id])
end
```

## Strong Parameters

### `income_params`

Permits the following parameters:

- `name` - The name of the income source (string, required)
- `frequency` - How often the income is received (string, default: "monthly")
- `estimated_amount` - Estimated income amount (decimal, default: 0.0)
- `active` - Whether the income is currently active (boolean, default: true)
- `user_id` - The user who owns this income (required)
- `auto_create` - Whether to automatically create income events (boolean, default: false)
- `due_date` - Date when income is typically received (date, nullable, required if auto_create is true)
- `last_payment_to_next_month` - Whether to defer last payment of month to next month (boolean, default: false)

## Access Control

- Requires user authentication (`before_action :authenticate_user!` from `Admin::BaseController`)
- Requires admin privileges (`before_action :ensure_admin` from `Admin::BaseController`)

## Related Models

- **Income** - The model being managed
- **User** - Required association for incomes
- **IncomeEvent** - Incomes can have many income events (optional association)

## Views

- `app/views/admin/incomes/index.html.erb` - List of all incomes
- `app/views/admin/incomes/show.html.erb` - Income details
- `app/views/admin/incomes/edit.html.erb` - Edit income form

## Usage Examples

### Updating an Income

```ruby
PATCH /admin/incomes/1
{
  income: {
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

