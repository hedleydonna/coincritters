# Admin::IncomeEventsController Documentation

## Overview

The `Admin::IncomeEventsController` provides full CRUD (Create, Read, Update, Delete) functionality for managing income events in the admin interface. Income events represent actual income received on specific dates.

## Location

`app/controllers/admin/income_events_controller.rb`

## Inheritance

- Inherits from `Admin::BaseController`
- Requires authentication and admin privileges

## Routes

All routes are namespaced under `/admin/income_events`:

- **GET** `/admin/income_events` - List all income events (index)
- **GET** `/admin/income_events/new` - Show new income event form
- **POST** `/admin/income_events` - Create a new income event
- **GET** `/admin/income_events/:id` - Show income event details
- **GET** `/admin/income_events/:id/edit` - Show edit income event form
- **PATCH/PUT** `/admin/income_events/:id` - Update an income event
- **DELETE** `/admin/income_events/:id` - Delete an income event

## Actions

### `index`

Lists all income events.

**Instance Variables:**
- `@income_events` - All income events, ordered by creation date (newest first), includes `user` and `income` associations

**Query Optimization:**
- Uses `includes(:user, :income)` to eager load associations and prevent N+1 queries

### `show`

Displays detailed information about a specific income event.

**Instance Variables:**
- `@income_event` - The income event to display (set by `before_action :set_income_event`)

### `new`

Shows the form to create a new income event.

**Instance Variables:**
- `@income_event` - A new, unsaved `IncomeEvent` instance
- `@users` - All users (for user selection dropdown)
- `@incomes` - All incomes (for income selection dropdown)

### `create`

Creates a new income event from form parameters.

**Success:**
- Redirects to `admin_income_event_path(@income_event)` with success notice: "Income event was successfully created."

**Failure:**
- Re-renders the `new` template with `:unprocessable_entity` status
- Re-sets `@users` and `@incomes` for the form

### `edit`

Shows the form to edit an existing income event.

**Instance Variables:**
- `@income_event` - The income event to edit (set by `before_action :set_income_event`)
- `@users` - All users (for user selection dropdown)
- `@incomes` - All incomes (for income selection dropdown)

### `update`

Updates an existing income event from form parameters.

**Success:**
- Redirects to `admin_income_event_path(@income_event)` with success notice: "Income event was successfully updated."

**Failure:**
- Re-renders the `edit` template with `:unprocessable_entity` status
- Re-sets `@users` and `@incomes` for the form

### `destroy`

Deletes an income event.

**Behavior:**
- Destroys the income event
- Redirects to `admin_income_events_path` with success notice: "Income event was successfully deleted."

## Callbacks

### `before_action :set_income_event`

Sets `@income_event` for `show`, `edit`, `update`, and `destroy` actions:

```ruby
def set_income_event
  @income_event = IncomeEvent.find(params[:id])
end
```

## Strong Parameters

### `income_event_params`

Permits the following parameters:

- `user_id` - The user who received this income (required)
- `income_id` - The income source this event is associated with (optional)
- `custom_label` - Custom label for the income event (string, nullable)
- `month_year` - The month/year this income is for, in "YYYY-MM" format (string, required)
- `assigned_month_year` - The month/year this income is assigned to (string, nullable)
- `received_on` - The date the income was received (date, required)
- `actual_amount` - The actual amount received (decimal, default: 0.0)
- `notes` - Optional notes about the income event (text, nullable)

## Access Control

- Requires user authentication (`before_action :authenticate_user!` from `Admin::BaseController`)
- Requires admin privileges (`before_action :ensure_admin` from `Admin::BaseController`)

## Related Models

- **IncomeEvent** - The model being managed
- **User** - Required association for income events
- **Income** - Optional association for income events

## Views

- `app/views/admin/income_events/index.html.erb` - List of all income events
- `app/views/admin/income_events/show.html.erb` - Income event details
- `app/views/admin/income_events/new.html.erb` - New income event form
- `app/views/admin/income_events/edit.html.erb` - Edit income event form

## Usage Examples

### Creating an Income Event

```ruby
POST /admin/income_events
{
  income_event: {
    user_id: 1,
    income_id: 2,
    custom_label: "December Salary",
    month_year: "2025-12",
    assigned_month_year: "2025-12",
    received_on: "2025-12-01",
    actual_amount: 5000.00,
    notes: "Monthly salary payment"
  }
}
```

### Creating a Standalone Income Event (No Income Source)

```ruby
POST /admin/income_events
{
  income_event: {
    user_id: 1,
    income_id: null,
    custom_label: "Freelance Payment",
    month_year: "2025-12",
    received_on: "2025-12-15",
    actual_amount: 1200.00
  }
}
```

---

**Last Updated**: December 2025

