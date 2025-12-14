# Admin::ExpenseController Documentation

## Overview

The `Admin::ExpenseController` provides full CRUD (Create, Read, Update, Delete) functionality for managing expense in the admin interface. Expense represent payment categories within monthly budgets.

## Location

`app/controllers/admin/expense_controller.rb`

## Inheritance

- Inherits from `Admin::BaseController`
- Requires authentication and admin privileges

## Routes

All routes are namespaced under `/admin/expense`:

- **GET** `/admin/expense` - List all expense (index)
- **GET** `/admin/expense/new` - Show new expenseform
- **POST** `/admin/expense` - Create a new envelope
- **GET** `/admin/expense/:id` - Show expensedetails
- **GET** `/admin/expense/:id/edit` - Show edit expenseform
- **PATCH/PUT** `/admin/expense/:id` - Update an envelope
- **DELETE** `/admin/expense/:id` - Delete an envelope

## Actions

### `index`

Lists all expense with pagination and statistics.

**Instance Variables:**
- `@expense` - All expense, ordered by creation date (newest first), includes `monthly_budget` and `user` associations
- `@total_expense` - Total count of all expense

**Query Optimization:**
- Uses `includes(monthly_budget: :user)` to eager load associations and prevent N+1 queries

### `show`

Displays detailed information about a specific expense

**Instance Variables:**
- `@expense - The expenseto display (set by `before_action :set_expense)

### `new`

Shows the form to create a new expense

**Instance Variables:**
- `@expense - A new, unsaved `Expense instance
- `@monthly_budgets` - All monthly budgets, ordered by creation date (newest first), includes `user` association
- `@expense_templates` - All active expensetemplates (ordered alphabetically by name via default_scope), includes `user` association

### `create`

Creates a new expensefrom form parameters.

**Success:**
- Redirects to `admin_envelope_path(@expense` with success notice: "Expensewas successfully created."

**Failure:**
- Re-renders the `new` template with `:unprocessable_entity` status
- Re-sets `@monthly_budgets` and `@expense_templates` for the form

### `edit`

Shows the form to edit an existing expense

**Instance Variables:**
- `@expense - The expenseto edit (set by `before_action :set_expense)
- `@monthly_budgets` - All monthly budgets, ordered by creation date (newest first), includes `user` association
- `@expense_templates` - All active expensetemplates (ordered alphabetically by name via default_scope), includes `user` association

### `update`

Updates an existing expensefrom form parameters.

**Success:**
- Redirects to `admin_envelope_path(@expense` with success notice: "Expensewas successfully updated."

**Failure:**
- Re-renders the `edit` template with `:unprocessable_entity` status
- Re-sets `@monthly_budgets` and `@expense_templates` for the form

### `destroy`

Deletes an expense

**Behavior:**
- Destroys the expense(cascades to associated payments)
- Redirects to `admin_expense_path` with success notice: "Expensewas successfully deleted."

## Callbacks

### `before_action :set_expense

Sets `@expense for `show`, `edit`, `update`, and `destroy` actions:

```ruby
def set_envelope
  @expense= Expensefind(params[:id])
end
```

## Strong Parameters

### `envelope_params`

Permits the following parameters:

- `monthly_budget_id` - The monthly budget this expensebelongs to
- `expense_template_id` - The expensetemplate this expenseis based on
- `allotted_amount` - The amount allocated to this expensefor the month
- `name` - Optional override name (uses template name if not provided)

**Note:** `frequency` and `due_date` always come from the template and cannot be set directly on expenses.

## Access Control

- Requires user authentication (`before_action :authenticate_user!` from `Admin::BaseController`)
- Requires admin privileges (`before_action :ensure_admin` from `Admin::BaseController`)

## Related Models

- **Expense* - The model being managed
- **MonthlyBudget** - Required association for expense
- **ExpenseTemplate** - Required association for expense

## Views

- `app/views/admin/expense/index.html.erb` - List of all expense
- `app/views/admin/expense/show.html.erb` - Expensedetails
- `app/views/admin/expense/new.html.erb` - New expenseform
- `app/views/admin/expense/edit.html.erb` - Edit expenseform

## Usage Examples

### Creating an Envelope

```ruby
POST /admin/expense
{
  expense {
    monthly_budget_id: 1,
    expense_template_id: 2,
    allotted_amount: 500.00,
    name: "Custom Name"  # Optional
  }
}
```

### Updating an Envelope

```ruby
PATCH /admin/expense/1
{
  expense {
    allotted_amount: 600.00,
    name: "Updated Name"  # Optional
  }
}
```

---

**Last Updated**: December 2025

