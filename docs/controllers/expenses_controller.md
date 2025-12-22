# ExpensesController Documentation

## Overview

The `ExpensesController` provides the main user interface for viewing and managing expenses. It handles creating both one-off and recurring expenses through a unified form, manages payments for expenses, and supports navigation context via `return_to` parameters. The controller automatically creates current and next month budgets and handles expense creation from templates.

## Location

`app/controllers/expenses_controller.rb`

## Inheritance

- Inherits from `ApplicationController`
- Requires authentication (`before_action :authenticate_user!`)

## Routes

All routes are under `/expenses`:
- **GET** `/expenses` - View expenses index (current month by default)
- **GET** `/expenses?month=YYYY-MM` - View specific month's expenses
- **GET** `/expenses/new` - Show unified expense creation form (one-off or recurring)
- **GET** `/expenses/new?month=YYYY-MM&return_to=money_map` - Show new expense form with navigation context
- **POST** `/expenses` - Create a new expense (one-off or recurring template)
- **GET** `/expenses/:id/edit` - Show edit expense form with payment management
- **GET** `/expenses/:id/edit?return_to=money_map` - Show edit form with navigation context
- **PATCH** `/expenses/:id` - Update an expense
- **DELETE** `/expenses/:id` - Delete a one-off expense (template-based expenses cannot be deleted)
- **POST** `/expenses/:id/add_payment` - Add a payment to an expense
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

Shows the unified form to create either a **one-off expense** or a **recurring expense template** with progressive disclosure.

**Form Behavior:**
- Single form handles both one-off and recurring expenses
- "How often?" dropdown with "Just once" option for one-offs
- When "Just once" is selected: creates a one-off expense
- When frequency is selected (weekly, biweekly, monthly, yearly): creates an expense template and auto-creates expenses for the month
- Progressive disclosure shows/hides fields based on selection

**Instance Variables:**
- `@budget` - The monthly budget to create expense in (from params or current)
- `@expense` - New, unsaved Expense instance
- `@viewing_month` - Month being viewed (for navigation)
- `@return_to` - Navigation context parameter ('money_map' or nil)

**Parameters:**
- `month` (optional) - Month to create expense for (YYYY-MM format)
- `return_to` (optional) - Navigation context ('money_map' to return to Money Map after creation)

**Form Fields:**
- `name` (required) - Name of the expense
- `allotted_amount` / `default_amount` (required) - Amount (label changes based on one-off vs recurring)
- `expected_on` / `due_date` (optional) - Date field (label changes based on one-off vs recurring)
- `frequency` (required for recurring) - How often the expense occurs (weekly, biweekly, monthly, yearly)

### `create`

Creates either a one-off expense or a recurring expense template with auto-created expenses.

**Behavior:**
- If `frequency == "just_once"`: Creates a one-off expense with the provided name and allotted_amount
- If `frequency` is set (weekly, biweekly, monthly, yearly):
  1. Creates an `ExpenseTemplate` with the provided name, frequency, due_date, and default_amount
  2. Auto-creates expense records for the current month based on frequency
  3. Each expense gets the template name copied to `expense.name`
  4. Each expense gets its own `expected_on` date for weekly/bi-weekly expenses

**Success:**
- If `return_to == 'money_map'`: Redirects to `money_map_path(scroll_to: 'spending-section')`
- Otherwise: Redirects to `expenses_path(month: @budget.month_year)` with notice
- Uses `status: :see_other` for Turbo compatibility

**Failure:**
- Re-renders the `new` template with `:unprocessable_entity` status
- Re-sets `@viewing_month` and `@return_to` for the form

**Parameters:**
- `month` (optional) - Month to create expense for (YYYY-MM format)
- `return_to` (optional) - Navigation context
- `frequency` (required) - "just_once" for one-off, or frequency string for recurring
- `expense[name]` - Expense name (required)
- `allotted_amount` or `default_amount` - Amount (name changes based on frequency)
- `due_date` or `expected_on` - Date (name changes based on frequency)

### `edit`

Shows the form to edit an existing expense, including payment management.

**Features:**
- Edit expense name and allotted amount
- View payment summary (Allotted | Spent | Remaining) with progress bar
- Add payments via quick payment form
- View and delete payment history
- "Pay Full Amount" button for convenience

**Instance Variables:**
- `@expense` - The expense being edited
- `@budget` - The monthly budget the expense belongs to
- `@expense_templates` - All active expense templates (for reference, not used in form)
- `@viewing_month` - Month being viewed (for navigation)
- `@return_to` - Navigation context parameter

**Parameters:**
- `id` - Expense ID to edit
- `return_to` (optional) - Navigation context ('money_map' to return to Money Map after update)

### `update`

Updates an existing expense.

**Success:**
- If `return_to == 'money_map'`: Redirects to `money_map_path(scroll_to: 'spending-section')`
- Otherwise: Redirects to `expenses_path(month: @budget.month_year)` with notice: "Expense updated!"
- Uses `status: :see_other` for Turbo compatibility

**Failure:**
- Re-renders the `edit` template with `:unprocessable_entity` status
- Re-sets `@expense_templates`, `@viewing_month`, and `@return_to` for the form

**Parameters:**
- `id` - Expense ID to update
- `return_to` (optional) - Navigation context
- `expense[name]` - Expense name (required)
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
The system only allows deletion of one-off expenses to prevent auto-recreation issues. When a template-based expense is deleted, the auto-creation logic (`auto_create_expenses`) would immediately recreate it on the next page view because it checks for existing expenses by template ID and date.

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

- `name` - Expense name (always required)
- `allotted_amount` - Amount allocated to this expense (decimal, default: 0.0)

**Note:** `expense_template_id` is no longer used in the form. Template-based expenses are created through the unified form which creates the template first, then auto-creates the expense records.

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

1. **Unified Expense Creation**: Single form handles both one-off and recurring expenses with progressive disclosure
2. **Payment Management**: Integrated payment tracking in expense edit form with quick payment entry and history
3. **Navigation Context**: `return_to` parameter support for seamless navigation back to Money Map
4. **Auto-Creation**: Automatically creates current and next month budgets on first view
5. **Multiple Expenses Per Template**: Supports weekly/bi-weekly templates that create multiple expense records per month, each with its own `expected_on` date
6. **Month Restrictions**:
   - Current month: Full access (edit expenses, add payments, delete one-offs)
   - Next month: Planning mode (edit allotted amounts, delete one-offs, no payments)
   - Past months: View-only
7. **Two Expense Types**:
   - Template-based: Created from expense templates (recurring, cannot be deleted)
   - One-off: Created without template (unique, non-recurring, can be deleted)
8. **Deletion Policy**: Only one-off expenses can be deleted to prevent auto-recreation conflicts
9. **Name Methodology**: Template names are copied to `expense.name` when created, allowing individual customization

---

**Last Updated**: December 2025

**Recent Changes (December 2025)**:
- Unified expense creation form for one-off and recurring expenses
- Added `add_payment` action for payment management
- Added `return_to` parameter support for navigation context
- Removed uniqueness constraints on expense names and template associations
- Added `expected_on` field for weekly/bi-weekly expenses
- Payment management integrated into expense edit form
- Template names are now copied to `expense.name` when creating expenses

