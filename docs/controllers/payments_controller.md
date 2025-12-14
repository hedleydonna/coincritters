# PaymentsController Documentation

## Overview

The `PaymentsController` provides functionality for users to add payment records to expenses. Payments can only be added to the current month's expenses (not future or past months).

## Location

`app/controllers/payments_controller.rb`

## Inheritance

- Inherits from `ApplicationController`
- Requires authentication (`before_action :authenticate_user!`)

## Routes

All routes are under `/payments`:
- **GET** `/payments/new` - Show new payment form
- **GET** `/payments/new?expense_id=1` - Show new payment form with expense pre-selected
- **GET** `/payments/new?month=YYYY-MM` - Show new payment form for specific month (redirects if not current month)
- **POST** `/payments` - Create a new payment

## Actions

### `new`

Shows the form to create a new payment record.

**Restrictions:**
- Only allows creating payments for the **current month**
- Redirects with alert if trying to create payment for future or past month

**Instance Variables:**
- `@budget` - The monthly budget for the current month (or from params if current month)
- `@payment` - New Payment instance with `spent_on` defaulted to today
- `@viewing_month` - Month being viewed (for navigation back to expenses)
- `@expenses` - List of expenses for the budget:
  - If `expense_id` param provided: Only that expense
  - Otherwise: All expenses in the budget, ordered by name

**Parameters:**
- `expense_id` (optional) - Pre-select this expense in the form
- `month` (optional) - Month parameter (must be current month, otherwise redirects)

### `create`

Creates a new payment record.

**Restrictions:**
- Only allows creating payments for the **current month**
- Redirects with alert if trying to create payment for future or past month
- Ensures expense belongs to user's current month budget

**Success:**
- Redirects to `expenses_path(month: @budget.month_year)` with notice: "Payment added!"

**Failure:**
- Re-renders the `new` template with `:unprocessable_entity` status
- Re-sets `@expenses` for the form

**Parameters:**
- `month` (optional) - Must be current month
- Payment params (see `payment_params` below)

## Strong Parameters

### `payment_params`

Permits the following parameters:

- `expense_id` - The expense this payment belongs to (required, must be in current month budget)
- `amount` - Payment amount (decimal, required, must be > 0)
- `spent_on` - Date the payment was made (date, required, defaults to today)
- `notes` - Optional notes about the payment (text)

## Access Control

- Requires user authentication (`before_action :authenticate_user!`)
- Users can only create payments for expenses in their own budgets
- Only allows payments for current month (enforced in both `new` and `create`)

## Related Models

- **Payment** - The model being created
- **Expense** - Payments belong to expenses
- **MonthlyBudget** - Payments are scoped through expenses to budgets

## Views

- `app/views/payments/new.html.erb` - New payment form

## Business Rules

1. **Current Month Only**: Payments can only be added to expenses in the current month
   - Future months: "Planning mode" - can edit allotted amounts but cannot add payments
   - Past months: "View only" - cannot edit or add payments
   - This prevents accidental spending from future budgets and maintains historical accuracy

2. **Expense Validation**: Payment's expense must belong to the user's current month budget

3. **Amount Validation**: Payment amount must be positive

## Usage Examples

### Creating a Payment

```ruby
POST /payments
{
  payment: {
    expense_id: 5,
    amount: 45.50,
    spent_on: "2025-12-14",
    notes: "Weekly groceries"
  }
}
```

### Creating a Payment with Expense Pre-selected

```ruby
GET /payments/new?expense_id=5
# Form opens with expense 5 pre-selected
```

### Attempting Payment on Future Month (Redirects)

```ruby
GET /payments/new?month=2026-01
# Redirects to expenses_path(month: "2026-01") with alert:
# "Payments can only be added to the current month."
```

## Integration with Expenses

- Payments are accessed through expenses: `expense.payments`
- Expense spent amount is calculated from payments: `expense.spent_amount = payments.sum(:amount)`
- Payments can be added from:
  - Expense list view: "+ Add payment" button (only shows for current month)
  - Individual expense cards: "Add payment" link (only shows for current month)

---

**Last Updated**: December 2025

