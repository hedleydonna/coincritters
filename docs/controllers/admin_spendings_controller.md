# Admin::SpendingsController Documentation

## Overview

The `Admin::SpendingsController` provides full CRUD (Create, Read, Update, Delete) functionality for managing spending records in the admin interface. Spending records track individual expenses within envelopes.

## Location

`app/controllers/admin/spendings_controller.rb`

## Inheritance

- Inherits from `Admin::BaseController`
- Requires authentication and admin privileges

## Routes

All routes are namespaced under `/admin/spendings`:

- **GET** `/admin/spendings` - List all spendings (index)
- **GET** `/admin/spendings/new` - Show new spending form
- **POST** `/admin/spendings` - Create a new spending
- **GET** `/admin/spendings/:id` - Show spending details
- **GET** `/admin/spendings/:id/edit` - Show edit spending form
- **PATCH/PUT** `/admin/spendings/:id` - Update a spending
- **DELETE** `/admin/spendings/:id` - Delete a spending

## Actions

### `index`

Lists all spending records with statistics.

**Instance Variables:**
- `@spendings` - All spendings, ordered by most recent (uses `recent` scope), includes `envelope`, `monthly_budget`, and `user` associations
- `@total_spendings` - Total count of all spending records
- `@total_amount` - Sum of all spending amounts

**Query Optimization:**
- Uses `includes(envelope: { monthly_budget: :user })` to eager load nested associations and prevent N+1 queries
- Uses the `recent` scope from the Spending model to order by date

### `show`

Displays detailed information about a specific spending record.

**Instance Variables:**
- `@spending` - The spending to display (set by `before_action :set_spending`)

### `new`

Shows the form to create a new spending record.

**Instance Variables:**
- `@spending` - A new, unsaved `Spending` instance
- `@envelopes` - All envelopes, ordered by creation date (newest first), includes `monthly_budget` and `user` associations

### `create`

Creates a new spending record from form parameters.

**Success:**
- Redirects to `admin_spending_path(@spending)` with success notice: "Spending was successfully created."

**Failure:**
- Re-renders the `new` template with `:unprocessable_entity` status
- Re-sets `@envelopes` for the form

### `edit`

Shows the form to edit an existing spending record.

**Instance Variables:**
- `@spending` - The spending to edit (set by `before_action :set_spending`)
- `@envelopes` - All envelopes, ordered by creation date (newest first), includes `monthly_budget` and `user` associations

### `update`

Updates an existing spending record from form parameters.

**Success:**
- Redirects to `admin_spending_path(@spending)` with success notice: "Spending was successfully updated."

**Failure:**
- Re-renders the `edit` template with `:unprocessable_entity` status
- Re-sets `@envelopes` for the form

### `destroy`

Deletes a spending record.

**Behavior:**
- Destroys the spending record
- Redirects to `admin_spendings_path` with success notice: "Spending was successfully deleted."

## Callbacks

### `before_action :set_spending`

Sets `@spending` for `show`, `edit`, `update`, and `destroy` actions:

```ruby
def set_spending
  @spending = Spending.find(params[:id])
end
```

## Strong Parameters

### `spending_params`

Permits the following parameters:

- `envelope_id` - The envelope this spending belongs to (required)
- `amount` - The spending amount (decimal, required, must be >= 0)
- `spent_on` - The date the spending occurred (date, required)
- `notes` - Optional notes about the spending (text, nullable)

## Access Control

- Requires user authentication (`before_action :authenticate_user!` from `Admin::BaseController`)
- Requires admin privileges (`before_action :ensure_admin` from `Admin::BaseController`)

## Related Models

- **Spending** - The model being managed
- **Envelope** - Required association for spendings
- **MonthlyBudget** - Spendings belong to budgets through envelopes
- **User** - Spendings belong to users through envelopes and budgets

## Views

- `app/views/admin/spendings/index.html.erb` - List of all spendings
- `app/views/admin/spendings/show.html.erb` - Spending details
- `app/views/admin/spendings/new.html.erb` - New spending form
- `app/views/admin/spendings/edit.html.erb` - Edit spending form

## Usage Examples

### Creating a Spending Record

```ruby
POST /admin/spendings
{
  spending: {
    envelope_id: 1,
    amount: 75.50,
    spent_on: "2025-12-15",
    notes: "Grocery shopping at Whole Foods"
  }
}
```

### Updating a Spending Record

```ruby
PATCH /admin/spendings/1
{
  spending: {
    amount: 80.00,
    notes: "Updated amount"
  }
}
```

---

**Last Updated**: December 2025

