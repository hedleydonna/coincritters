# Admin::PaymentsController Documentation

## Overview

The `Admin::PaymentsController` provides full CRUD (Create, Read, Update, Delete) functionality for managing payment records in the admin interface. Payment records track individual expenses within expense.

## Location

`app/controllers/admin/payments_controller.rb`

## Inheritance

- Inherits from `Admin::BaseController`
- Requires authentication and admin privileges

## Routes

All routes are namespaced under `/admin/payments`:

- **GET** `/admin/payments` - List all payments (index)
- **GET** `/admin/payments/new` - Show new payment form
- **POST** `/admin/payments` - Create a new payment
- **GET** `/admin/payments/:id` - Show payment details
- **GET** `/admin/payments/:id/edit` - Show edit payment form
- **PATCH/PUT** `/admin/payments/:id` - Update a payment
- **DELETE** `/admin/payments/:id` - Delete a payment

## Actions

### `index`

Lists all payment records with statistics.

**Instance Variables:**
- `@payments` - All payments, ordered by most recent (uses `recent` scope), includes `expense, `monthly_budget`, and `user` associations
- `@total_payments` - Total count of all payment records
- `@total_amount` - Sum of all payment amounts

**Query Optimization:**
- Uses `includes(expense { monthly_budget: :user })` to eager load nested associations and prevent N+1 queries
- Uses the `recent` scope from the Payment model to order by date

### `show`

Displays detailed information about a specific payment record.

**Instance Variables:**
- `@payment` - The payment to display (set by `before_action :set_payment`)

### `new`

Shows the form to create a new payment record.

**Instance Variables:**
- `@payment` - A new, unsaved `Payment` instance
- `@expense` - All expense, ordered by creation date (newest first), includes `monthly_budget` and `user` associations

### `create`

Creates a new payment record from form parameters.

**Success:**
- Redirects to `admin_payment_path(@payment)` with success notice: "Payment was successfully created."

**Failure:**
- Re-renders the `new` template with `:unprocessable_entity` status
- Re-sets `@expense` for the form

### `edit`

Shows the form to edit an existing payment record.

**Instance Variables:**
- `@payment` - The payment to edit (set by `before_action :set_payment`)
- `@expense` - All expense, ordered by creation date (newest first), includes `monthly_budget` and `user` associations

### `update`

Updates an existing payment record from form parameters.

**Success:**
- Redirects to `admin_payment_path(@payment)` with success notice: "Payment was successfully updated."

**Failure:**
- Re-renders the `edit` template with `:unprocessable_entity` status
- Re-sets `@expense` for the form

### `destroy`

Deletes a payment record.

**Behavior:**
- Destroys the payment record
- Redirects to `admin_payments_path` with success notice: "Payment was successfully deleted."

## Callbacks

### `before_action :set_payment`

Sets `@payment` for `show`, `edit`, `update`, and `destroy` actions:

```ruby
def set_payment
  @payment = Payment.find(params[:id])
end
```

## Strong Parameters

### `payment_params`

Permits the following parameters:

- `envelope_id` - The expensethis payment belongs to (required)
- `amount` - The payment amount (decimal, required, must be >= 0)
- `spent_on` - The date the payment occurred (date, required)
- `notes` - Optional notes about the payment (text, nullable)

## Access Control

- Requires user authentication (`before_action :authenticate_user!` from `Admin::BaseController`)
- Requires admin privileges (`before_action :ensure_admin` from `Admin::BaseController`)

## Related Models

- **Payment** - The model being managed
- **Expense* - Required association for payments
- **MonthlyBudget** - Payments belong to budgets through expense
- **User** - Payments belong to users through expense and budgets

## Views

- `app/views/admin/payments/index.html.erb` - List of all payments
- `app/views/admin/payments/show.html.erb` - Payment details
- `app/views/admin/payments/new.html.erb` - New payment form
- `app/views/admin/payments/edit.html.erb` - Edit payment form

## Usage Examples

### Creating a Payment Record

```ruby
POST /admin/payments
{
  payment: {
    envelope_id: 1,
    amount: 75.50,
    spent_on: "2025-12-15",
    notes: "Grocery shopping at Whole Foods"
  }
}
```

### Updating a Payment Record

```ruby
PATCH /admin/payments/1
{
  payment: {
    amount: 80.00,
    notes: "Updated amount"
  }
}
```

---

**Last Updated**: December 2025

