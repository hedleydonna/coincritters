# ExpensesController Documentation

## Overview

The `ExpensesController` provides the main user interface for viewing and managing expenses in the Money Map. It automatically creates current and next month budgets, provides tab navigation between months, and handles creating both template-based and one-off expenses.

## Location

`app/controllers/expenses_controller.rb`

## Inheritance

- Inherits from `ApplicationController`
- Requires authentication (`before_action :authenticate_user!`)

## Routes

All routes are under `/expenses`:
- **GET** `/expenses` - View Money Map (index)
- **GET** `/expenses?month=YYYY-MM` - View specific month's Money Map
- **GET** `/expenses/new` - Show new expense form
- **GET** `/expenses/new?month=YYYY-MM` - Show new expense form for specific month
- **POST** `/expenses` - Create a new expense
- **GET** `/expenses/:id/edit` - Show edit expense form
- **GET** `/expenses/:id/edit?month=YYYY-MM` - Show edit expense form for specific month
- **PATCH** `/expenses/:id` - Update an expense
- **DELETE** `/expenses/:id` - Delete a one-off expense (template-based expenses cannot be deleted)
- **POST** `/expenses/:id/mark_paid` - Mark expense as fully paid (creates payment for remaining amount)
- **POST** `/expenses/:expense_id/sweep_to_savings` - Sweep flex fund to savings expense
- **POST** `/expenses/start_next_month` - Create next month's budget (deprecated - auto-created now)

## Actions

### `index`

The main Money Map view. Automatically creates current and next month budgets if they don't exist.

**Auto-Creation Behavior:**
- Automatically creates current month budget if missing
- Automatically creates next month budget if missing
- Always regenerates expenses from active templates (auto_create: true) for current month when visiting
- Regenerates expenses for the month being viewed (if current or next month)
- This ensures newly created expense templates with auto_create: true immediately appear in the spending list

**Filtering:**
- Expenses from deleted templates (where `expense_template.deleted_at IS NOT NULL`) are automatically filtered out
- One-off expenses (no template) are always shown
- Uses LEFT JOIN to check template deletion status without excluding one-off expenses

**Month Navigation:**
- Supports `month` parameter to view specific months
- Defaults to current month if no parameter provided
- Redirects to current month if trying to view non-existent future month

**Instance Variables:**
- `@budget` - The monthly budget being viewed
- `@expenses` - All expenses for the budget, ordered by name (excludes expenses from deleted templates)
- `@total_spent` - Total spent across all expenses (calculated from payments)
- `@remaining` - Remaining amount (total_actual_income - total_spent)
- `@bank_match` - Whether bank balance matches expected balance (within $50 tolerance)
- `@bank_difference` - Difference between bank balance and expected balance
- `@current_month` - Current month string (YYYY-MM)
- `@next_month_str` - Next month string (YYYY-MM)
- `@viewing_month` - Month being viewed (YYYY-MM)
- `@is_current_month` - Boolean: viewing current month
- `@is_next_month` - Boolean: viewing next month
- `@is_past_month` - Boolean: viewing past month
- `@current_budget` - Current month's budget object
- `@next_budget` - Next month's budget object
- `@past_months` - Array of past month strings for dropdown

**View Mode Indicators:**
- Current month: Full editing, can add payments
- Next month: Planning mode - can edit allotted amounts, cannot add payments
- Past months: View-only - cannot edit or add payments

### `new`

Shows the form to create a new **one-off expense** (not template-based).

**Note:** This form is specifically for creating one-off expenses. Template-based expenses are automatically created from expense templates with `auto_create: true` when viewing the expenses page.

**Instance Variables:**
- `@budget` - The monthly budget to create expense in (from params or current)
- `@expense` - New, unsaved Expense instance
- `@viewing_month` - Month being viewed (for navigation)

**Parameters:**
- `month` (optional) - Month to create expense for (YYYY-MM format)

**Form Fields:**
- `name` (required) - Name of the one-off expense
- `allotted_amount` (required) - Amount to allocate

### `create`

Creates a new one-off expense.

**Success:**
- Redirects to `expenses_path(month: @budget.month_year)` with notice: "Expense added!"
- Uses `data: { turbo: false }` to force full page reload, ensuring the new expense appears immediately

**Failure:**
- Re-renders the `new` template with `:unprocessable_entity` status
- Re-sets `@viewing_month` for the form

**Parameters:**
- `expense[month_year]` or `month` - Month to create expense for
- `expense[name]` - Expense name (required for one-off expenses)
- `expense[allotted_amount]` - Amount to allocate

**Note:** The `expense_template_id` parameter is not used in the new expense form - this form is specifically for one-off expenses only.

### `edit`

Shows the form to edit an existing expense.

**Instance Variables:**
- `@expense` - The expense being edited
- `@budget` - The monthly budget the expense belongs to
- `@expense_templates` - All active expense templates for user selection
- `@viewing_month` - Month being viewed (for navigation)

**Parameters:**
- `id` - Expense ID to edit
- `month` (optional) - Month being viewed (YYYY-MM format)

### `update`

Updates an existing expense.

**Success:**
- Redirects to `expenses_path(month: @budget.month_year)` with notice: "Expense updated!"

**Failure:**
- Re-renders the `edit` template with `:unprocessable_entity` status
- Re-sets `@expense_templates` and `@viewing_month` for the form

**Parameters:**
- `id` - Expense ID to update
- `expense[expense_template_id]` - Template ID (optional)
- `expense[name]` - Expense name
- `expense[allotted_amount]` - Amount to allocate

### `mark_paid`

Marks an expense as fully paid by creating a payment for the remaining amount needed.

**Behavior:**
- Only works for current month expenses
- Calculates amount needed: `allotted_amount - spent_amount`
- Creates a payment for that amount with `spent_on: Date.today`
- Adds note: "Marked as paid"

**Success:**
- Redirects to `expenses_path(month: current_month)` with notice showing amount paid

**Restrictions:**
- Only works for current month (not next or past months)
- If expense is already paid, shows notice
- If amount needed is <= 0, shows alert

**Parameters:**
- `id` - Expense ID to mark as paid

### `sweep_to_savings`

Sweeps money from the flex fund (unassigned money) to a savings expense.

**Behavior:**
- Only works for current month
- Only works for expenses with names containing "savings" or "emergency" (case-insensitive)
- Increases the expense's `allotted_amount` by the swept amount
- Uses `@budget.unassigned` to determine available flex fund

**Success:**
- Redirects to `expenses_path(month: month_year)` with success notice

**Restrictions:**
- Only works for current month
- Only works for savings expenses
- Requires positive flex fund amount

**Parameters:**
- `expense_id` - Savings expense ID
- `amount` - Amount to sweep (must be <= flex fund)
- `month` - Month being viewed

### `destroy`

Deletes a one-off expense (hard delete). Template-based expenses cannot be deleted.

**Restrictions:**
- **Only one-off expenses can be deleted** (`expense_template_id IS NULL`)
- Template-based expenses cannot be deleted (they would be auto-recreated)
- If attempting to delete a template-based expense, redirects with alert suggesting to edit the template or set amount to $0

**Behavior:**
- Hard deletes the expense record
- Automatically deletes all associated payments (via `dependent: :destroy` on Expense model)
- Recalculates monthly budget totals

**Success:**
- Redirects to `expenses_path(month: month_year)` with notice: "Expense deleted."

**Failure:**
- Redirects with alert if attempting to delete a template-based expense

**Parameters:**
- `id` - Expense ID to delete
- `month` (optional) - Month parameter for redirect

**Deletion Strategy:**
The system only allows deletion of one-off expenses to prevent auto-recreation issues. When a template-based expense is deleted, the auto-creation logic (`auto_create_expenses`) would immediately recreate it on the next page view because it checks `expenses.exists?(expense_template_id: template.id)`. 

For template-based expenses users don't want:
- Edit the template (turn off auto-create, delete the template, etc.)
- Set the expense's `allotted_amount` to $0 for that month
- The expense remains but with zero allocation

This preserves the integrity of the template system while allowing users to remove mistakes (one-off expenses).

### `start_next_month` (Deprecated)

This action is kept for backward compatibility but is no longer needed since next month is automatically created when viewing the Money Map.

## Strong Parameters

### `expense_params`

Permits the following parameters:

- `expense_template_id` - The expense template this expense is based on (optional - can be null for one-off expenses)
- `allotted_amount` - Amount allocated to this expense (decimal, default: 0.0)
- `name` - Expense name (required for one-off expenses, optional override for template-based expenses)

## Access Control

- Requires user authentication (`before_action :authenticate_user!`)
- Users can only view/manage their own budgets and expenses

## Related Models

- **Expense** - The model being managed (can be template-based or one-off)
- **ExpenseTemplate** - Optional association for template-based expenses
- **MonthlyBudget** - Required association - expense belongs to a budget
- **Payment** - Expenses have many payments (only for current month)

## Views

- `app/views/expenses/index.html.erb` - Money Map view with tab navigation
- `app/views/expenses/new.html.erb` - New expense form
- `app/views/expenses/edit.html.erb` - Edit expense form

## Usage Examples

### Creating a Template-Based Expense

```ruby
POST /expenses
{
  expense: {
    monthly_budget_id: 1,
    expense_template_id: 5,
    allotted_amount: 500.00
  }
}
```

### Creating a One-Off Expense

```ruby
POST /expenses
{
  expense: {
    monthly_budget_id: 1,
    expense_template_id: null,  # or omit entirely
    name: "Birthday Gift",
    allotted_amount: 50.00
  }
}
```

### Viewing a Specific Month

```ruby
GET /expenses?month=2026-01
```

### Marking an Expense as Paid

```ruby
POST /expenses/123/mark_paid
# Creates payment for remaining amount needed to fully pay the expense
```

### Editing an Expense

```ruby
GET /expenses/123/edit?month=2025-12
PATCH /expenses/123
{
  expense: {
    allotted_amount: 600.00
  }
}
```

## Key Features

1. **Auto-Creation**: Automatically creates current and next month budgets on first view
2. **Tab Navigation**: Easy switching between current and next month
3. **Month Restrictions**:
   - Current month: Full access (edit expenses, add payments, delete one-offs)
   - Next month: Planning mode (edit allotted amounts, delete one-offs, no payments)
   - Past months: View-only
4. **Two Expense Types**:
   - Template-based: Created from expense templates (recurring, cannot be deleted)
   - One-off: Created without template (unique, non-recurring, can be deleted)
5. **Deletion Policy**: Only one-off expenses can be deleted to prevent auto-recreation conflicts

---

**Last Updated**: January 2026

**Recent Changes (January 2026)**:
- Added `destroy` action for one-off expenses only
- Template-based expenses cannot be deleted (prevents auto-recreation conflicts)
- Delete button only appears for one-off expenses in the UI

