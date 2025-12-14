# Admin::MonthlyBudgetsController Documentation

## Overview

The `Admin::MonthlyBudgetsController` provides full CRUD (Create, Read, Update, Delete) functionality for managing monthly budgets in the admin interface. Monthly budgets represent a user's financial plan for a specific month.

## Location

`app/controllers/admin/monthly_budgets_controller.rb`

## Inheritance

- Inherits from `Admin::BaseController`
- Requires authentication and admin privileges

## Routes

All routes are namespaced under `/admin/monthly_budgets`:

- **GET** `/admin/monthly_budgets` - List all monthly budgets (index)
- **GET** `/admin/monthly_budgets/new` - Show new budget form
- **POST** `/admin/monthly_budgets` - Create a new budget
- **GET** `/admin/monthly_budgets/:id` - Show budget details
- **GET** `/admin/monthly_budgets/:id/edit` - Show edit budget form
- **PATCH/PUT** `/admin/monthly_budgets/:id` - Update a budget
- **DELETE** `/admin/monthly_budgets/:id` - Delete a budget

## Actions

### `index`

Lists all monthly budgets with statistics.

**Instance Variables:**
- `@monthly_budgets` - All monthly budgets, ordered by creation date (newest first), includes `user` association
- `@total_budgets` - Total count of all monthly budgets

**Query Optimization:**
- Uses `includes(:user)` to eager load user associations and prevent N+1 queries

### `show`

Displays detailed information about a specific monthly budget.

**Instance Variables:**
- `@monthly_budget` - The budget to display (set by `before_action :set_monthly_budget`)

### `new`

Shows the form to create a new monthly budget.

**Instance Variables:**
- `@monthly_budget` - A new, unsaved `MonthlyBudget` instance
- `@users` - All users (for user selection dropdown)

### `create`

Creates a new monthly budget from form parameters.

**Success:**
- Redirects to `admin_monthly_budget_path(@monthly_budget)` with success notice: "Monthly budget was successfully created."

**Failure:**
- Re-renders the `new` template with `:unprocessable_entity` status
- Re-sets `@users` for the form

### `edit`

Shows the form to edit an existing monthly budget.

**Instance Variables:**
- `@monthly_budget` - The budget to edit (set by `before_action :set_monthly_budget`)
- `@users` - All users (for user selection dropdown)

### `update`

Updates an existing monthly budget from form parameters.

**Success:**
- Redirects to `admin_monthly_budget_path(@monthly_budget)` with success notice: "Monthly budget was successfully updated."

**Failure:**
- Re-renders the `edit` template with `:unprocessable_entity` status
- Re-sets `@users` for the form

### `destroy`

Deletes a monthly budget.

**Behavior:**
- Destroys the budget (cascades to associated expense and payments)
- Redirects to `admin_monthly_budgets_path` with success notice: "Monthly budget was successfully deleted."

## Callbacks

### `before_action :set_monthly_budget`

Sets `@monthly_budget` for `show`, `edit`, `update`, and `destroy` actions:

```ruby
def set_monthly_budget
  @monthly_budget = MonthlyBudget.find(params[:id])
end
```

## Strong Parameters

### `monthly_budget_params`

Permits the following parameters:

- `user_id` - The user who owns this budget
- `month_year` - The month and year in "YYYY-MM" format (required, unique per user)
- `total_actual_income` - Total actual income for the month (decimal, default: 0.0)
- `flex_fund` - Flexible fund amount (decimal, default: 0.0)
- `bank_balance` - Bank balance at the start of the month (decimal, nullable)

## Access Control

- Requires user authentication (`before_action :authenticate_user!` from `Admin::BaseController`)
- Requires admin privileges (`before_action :ensure_admin` from `Admin::BaseController`)

## Related Models

- **MonthlyBudget** - The model being managed
- **User** - Required association for budgets
- **Expense* - Budgets have many expense (cascade delete)
- **Payment** - Budgets have many payments through expense (cascade delete)

## Views

- `app/views/admin/monthly_budgets/index.html.erb` - List of all monthly budgets
- `app/views/admin/monthly_budgets/show.html.erb` - Budget details
- `app/views/admin/monthly_budgets/new.html.erb` - New budget form
- `app/views/admin/monthly_budgets/edit.html.erb` - Edit budget form

## Usage Examples

### Creating a Monthly Budget

```ruby
POST /admin/monthly_budgets
{
  monthly_budget: {
    user_id: 1,
    month_year: "2025-12",
    total_actual_income: 5000.00,
    flex_fund: 200.00,
    bank_balance: 1500.00
  }
}
```

### Updating a Monthly Budget

```ruby
PATCH /admin/monthly_budgets/1
{
  monthly_budget: {
    total_actual_income: 5500.00,
    flex_fund: 250.00
  }
}
```

---

**Last Updated**: December 2025

