# IncomeEventsController Documentation

## Overview

The `IncomeEventsController` provides functionality for users to view and manage income events. It supports a unified form for creating both one-off and recurring income, editing income events with actual vs expected amount tracking, and managing income receipt status. The controller handles navigation context via `return_to` parameters for seamless integration with the Money Map.

## Location

`app/controllers/income_events_controller.rb`

## Inheritance

- Inherits from `ApplicationController`
- Requires authentication (`before_action :authenticate_user!`)

## Routes

All routes are under `/income_events`:
- **GET** `/income_events` - View income events (current month by default)
- **GET** `/income_events?month=YYYY-MM` - View income events for specific month (current or next only)
- **GET** `/income_events/new` - Show unified income creation form (one-off or recurring)
- **GET** `/income_events/new?return_to=money_map` - Show new form with navigation context
- **POST** `/income_events` - Create a new income event or template
- **GET** `/income_events/:id` - Show quick action page for marking income as received (template-based only)
- **GET** `/income_events/:id?return_to=money_map` - Show page with navigation context
- **GET** `/income_events/:id/edit` - Edit an income event
- **GET** `/income_events/:id/edit?return_to=money_map` - Edit with navigation context
- **PATCH** `/income_events/:id` - Update an income event
- **PATCH** `/income_events/:id/mark_received` - Mark event as received (sets actual_amount to estimated_amount)
- **PATCH** `/income_events/:id/reset_to_expected` - Reset actual_amount to 0
- **DELETE** `/income_events/:id` - Delete a one-off income event (template-based events cannot be deleted)

## Actions

### `index`

Displays income events for current or next month.

**Restrictions:**
- Only allows viewing current or next month
- Redirects with alert if trying to view other months

**Auto-Creation Behavior:**
- Automatically creates current month budget if missing
- Automatically creates next month budget if missing (when viewing next month)
- Always regenerates income events for current month when visiting
- Regenerates income events for next month if budget exists

**Income Event Logic:**
- **Current month**: Shows all events for current month
- **Next month**: Shows all events for next month
- **Note**: Deferral functionality has been removed. Income events always count in their `month_year`. Automatic carryover handles month-to-month balance.

**Filtering:**
- Income events from deleted templates (where `income_template.deleted_at IS NOT NULL`) are automatically filtered out
- One-off income events (no template) are always shown
- Uses LEFT JOIN to check template deletion status without excluding one-off events

**Instance Variables:**
- `@budget` - The monthly budget being viewed
- `@income_events` - Income events for the viewing month (includes deferred from previous month, excludes events from deleted templates)
- `@total_expected` - Expected income for the month (from `@budget.expected_income`)
- `@total_actual` - Actual income received (from `@budget.total_actual_income`)
- `@current_month` - Current month string (YYYY-MM)
- `@next_month_str` - Next month string (YYYY-MM)
- `@viewing_month` - Month being viewed (YYYY-MM)
- `@is_current_month` - Boolean: viewing current month
- `@is_next_month` - Boolean: viewing next month

**Parameters:**
- `month` (optional) - Month to view (must be current or next month)

### `new`

Shows the unified form to create either a **one-off income event** or a **recurring income template** with progressive disclosure.

**Form Behavior:**
- Single form handles both one-off and recurring income
- "How often?" dropdown with "Just once" option for one-offs
- When "Just once" is selected: creates a one-off income event
- When frequency is selected (weekly, biweekly, monthly, yearly): creates an income template and auto-creates income events for the month
- Progressive disclosure shows/hides fields based on selection
- Amount field label changes dynamically ("Amount" for one-off, "Estimated Amount" for recurring)
- Date field is always visible and label changes based on selection

**Instance Variables:**
- `@income_event` - New IncomeEvent instance (for one-off) or placeholder
- `@return_to` - Navigation context parameter ('money_map' or nil)

**Parameters:**
- `return_to` (optional) - Navigation context ('money_map' to return to Money Map after creation)

### `create`

Creates either a one-off income event or a recurring income template with auto-created events.

**Behavior:**
- If `frequency == "just_once"`: Creates a one-off income event with the provided name, amount, and date
- If `frequency` is set (weekly, biweekly, monthly, yearly):
  1. Creates an `IncomeTemplate` with the provided name, frequency, due_date, and estimated_amount
  2. Auto-creates income event records for the current month based on frequency
  3. Sets `actual_amount` to `estimated_amount` only if `received_on` is today, otherwise sets to 0
  4. Sets `month_year` from each event's `received_on` date

**Success:**
- If `return_to == 'money_map'`: Redirects to `money_map_path(scroll_to: 'money-in-section')`
- Otherwise: Redirects to `income_events_path` or `income_templates_path` with notice
- Uses `status: :see_other` for Turbo compatibility

**Failure:**
- Re-renders the `new` template with `:unprocessable_entity` status
- Re-sets `@return_to` for the form

**Parameters:**
- `return_to` (optional) - Navigation context
- `frequency` (required) - "just_once" for one-off, or frequency string for recurring
- `income_event[custom_label]` or template name - Income name (required)
- `income_event[actual_amount]` or `estimated_amount` - Amount (name changes based on frequency)
- `income_event[received_on]` or `due_date` - Date (name changes based on frequency)
- `income_event[notes]` - Optional notes

### `show`

Shows a quick action page for marking template-based income events as received. This is the default page when clicking on an unreceived income event from the Money Map.

**Purpose:**
- Provides a focused, single-purpose page for the most common action (marking as received)
- Separates quick action from detailed editing
- Reduces cognitive load with clear, prominent action button

**Behavior:**
- Only shows for template-based income events that haven't been received yet (`actual_amount == 0`)
- If already received, no template, or no estimated amount, redirects to `edit` page
- Displays income name, expected date, and expected amount prominently
- Large "Received $X.XX" button for quick action
- "Edit [Event Name]" link to access full edit form

**Navigation:**
- Swipe-back gesture (left to right) navigates back to Money Map
- Uses `swipe_back_controller.js` Stimulus controller
- Back URL includes `scroll_to=money-in-section` parameter

**Instance Variables:**
- `@income_event` - The income event being viewed
- `@return_to` - Navigation context parameter

**Parameters:**
- `id` - Income event ID to show
- `return_to` (optional) - Navigation context ('money_map' to return to Money Map after action)

**Views:**
- `app/views/income_events/show.html.erb` - Quick action page with prominent "Received" button

### `edit`

Shows the form to edit an existing income event. This is accessed from the show page via "Edit [Event Name]" link, or directly for events that have already been received.

**Features:**
- Edit income event details (name, amount, date, notes)
- Amount field always visible (pre-filled with estimated amount for template-based income)
- For template-based income: Amount field is pre-filled with estimated amount when `actual_amount == 0`
- For one-off income: Amount field is always required
- Swipe-back gesture (left to right) navigates back to show page (if came from show) or Money Map
- Uses `swipe_back_controller.js` Stimulus controller

**Navigation:**
- Cancel button navigates back with `scroll_to` parameter
- Update button navigates back with `scroll_to` parameter
- Swipe-back navigates to show page (if came from show) or Money Map

**Instance Variables:**
- `@income_event` - The income event being edited
- `@return_to` - Navigation context parameter

**Parameters:**
- `id` - Income event ID to edit
- `return_to` (optional) - Navigation context ('money_map' to return to Money Map after update)

### `update`

Updates an existing income event.

**Behavior:**
- Updates `month_year` if `received_on` changed
- Allows updating name, amounts, date, and notes
- Validates that actual_amount can differ from estimated_amount

**Success:**
- If `return_to == 'money_map'`: Redirects to `money_map_path(scroll_to: 'money-in-section')`
- Otherwise: Redirects to `income_events_path` or `income_templates_path` with notice
- Uses `status: :see_other` for Turbo compatibility

**Failure:**
- Re-renders the `edit` template with `:unprocessable_entity` status
- Re-sets `@return_to` for the form

**Parameters:**
- `id` - Income event ID to update
- `return_to` (optional) - Navigation context
- `income_event[custom_label]` - Custom label (for one-off events) or name
- `income_event[received_on]` - Date received
- `income_event[actual_amount]` - Amount received (can differ from estimated)
- `income_event[notes]` - Optional notes

### `mark_received`

Marks an income event as received by setting actual_amount to estimated_amount.

**Behavior:**
- Only works for events linked to income templates
- Sets `actual_amount` to template's `estimated_amount` (or 0 if no estimated amount)
- Uses `update` method to trigger validations and callbacks

**Success:**
- If `return_to == 'money_map'`: Redirects to `money_map_path(scroll_to: 'money-in-section')`
- Otherwise: Redirects to `income_events_path` with notice
- Uses `status: :see_other` for Turbo compatibility

**Failure:**
- Redirects with alert if no expected amount is set

**Parameters:**
- `id` - Income event ID to mark as received
- `return_to` (optional) - Navigation context

### `reset_to_expected`

Resets the actual_amount to 0 (unmarks as received).

**Behavior:**
- Sets `actual_amount` to 0
- Allows user to reset if they marked as received by mistake

**Success:**
- If `return_to == 'money_map'`: Redirects to `money_map_path(scroll_to: 'money-in-section')`
- Otherwise: Redirects to `income_events_path` with notice
- Uses `status: :see_other` for Turbo compatibility

**Parameters:**
- `id` - Income event ID to reset
- `return_to` (optional) - Navigation context

### `mark_received`

Marks an income event as received by setting actual_amount to estimated_amount.

**Behavior:**
- Only works for events linked to income templates
- Sets `actual_amount` to template's `estimated_amount`
- Requires template to have `estimated_amount > 0`

**Success:**
- Redirects to `income_events_path` with notice showing amount

**Failure:**
- Redirects with alert if no expected amount is set

**Parameters:**
- `id` - Income event ID to mark as received

### `destroy`

Deletes a one-off income event (hard delete). Template-based income events cannot be deleted.

**Restrictions:**
- **Only one-off income events can be deleted** (`income_template_id IS NULL`)
- Template-based income events cannot be deleted (they would be auto-recreated)
- If attempting to delete a template-based event, redirects with alert suggesting to edit the template or set amount to $0

**Behavior:**
- Hard deletes the income event record
- Recalculates monthly budget income totals automatically
- Shows notice with amount removed

**Success:**
- Redirects to `income_events_path` with notice showing amount removed: "Income event removed. $X.XX has been removed from your budget."

**Failure:**
- Redirects with alert if attempting to delete a template-based income event

**Parameters:**
- `id` - Income event ID to delete

**Deletion Strategy:**
The system only allows deletion of one-off income events to prevent auto-recreation issues. When a template-based income event is deleted, the auto-creation logic (`auto_create_income_events`) would immediately recreate it on the next page view because it checks for existing events by template ID and date.

For template-based income events users don't want:
- Edit the template (turn off auto-create, delete the template, etc.)
- Set the event's `actual_amount` to $0
- The event remains but with zero amount

This preserves the integrity of the template system while allowing users to remove mistakes (one-off income events).

## Strong Parameters

### `income_event_params`

**For `create` action:**
- `custom_label` - Label for one-off income (required for one-off)
- `received_on` - Date income was received
- `actual_amount` - Amount received (for one-off)
- `notes` - Optional notes

**For `update` action:**
- `custom_label` - Custom label or name
- `received_on` - Date received
- `actual_amount` - Amount received (can differ from estimated)
- `notes` - Optional notes

**Note:** `apply_to_next_month` and `income_template_id` are no longer used. Deferral functionality has been removed in favor of automatic carryover.

## Access Control

- Requires user authentication (`before_action :authenticate_user!`)
- Users can only view/manage their own income events
- Only allows viewing current or next month

## Related Models

- **IncomeEvent** - The model being managed
- **IncomeTemplate** - Optional association for template-based events
- **MonthlyBudget** - Income events update budget totals automatically

## Views

- `app/views/income_events/index.html.erb` - Income events list with month navigation
  - Uses icon-only buttons for actions (Received, Defer, Edit, Delete)
  - Supports swipe gestures for marking events as received
- `app/views/income_events/new.html.erb` - Unified income creation form (one-off or recurring)
- `app/views/income_events/show.html.erb` - Quick action page for marking income as received
  - Prominent "Received $X.XX" button
  - "Edit [Event Name]" link to full edit form
  - Swipe-back navigation support
- `app/views/income_events/edit.html.erb` - Edit income event form
  - Full editing capabilities
  - Swipe-back navigation support
  - Amount field pre-filled for template-based income

## Business Rules

1. **Month Restrictions**: Only current and next month can be viewed
2. **Unified Creation**: Single form creates either one-off events or recurring templates
3. **Auto-Creation**: Income events are auto-created from templates when viewing a month
4. **Auto-Fill Logic**: When income events are created, `actual_amount` is set to `estimated_amount` only if `received_on` is today, otherwise set to 0
5. **Expected vs Actual**: Users can track when actual amount received differs from expected amount
6. **Budget Updates**: Monthly budget totals update automatically when events change
7. **Deletion Policy**: Only one-off income events can be deleted to prevent auto-recreation conflicts
8. **Navigation Context**: `return_to` parameter supports seamless navigation back to Money Map

## Usage Examples

### Viewing Current Month Income

```ruby
GET /income_events
# Shows current month income events
```

### Viewing Next Month Income

```ruby
GET /income_events?month=2026-01
# Shows next month income events (if current month is December 2025)
```

### Creating a One-Off Income Event

```ruby
POST /income_events
{
  income_event: {
    custom_label: "Birthday Gift",
    received_on: "2025-12-15",
    actual_amount: 500.00,
    notes: "From family"
  }
}
```

### Marking as Received

```ruby
PATCH /income_events/123/mark_received?return_to=money_map
# Sets actual_amount to estimated_amount
```

### Resetting to Expected

```ruby
PATCH /income_events/123/reset_to_expected?return_to=money_map
# Sets actual_amount to 0
```

### Marking as Received

```ruby
POST /income_events/123/mark_received
# Sets actual_amount to template's estimated_amount
```

## UI Features

1. **Unified Form**: Single form with progressive disclosure for one-off and recurring income
2. **Quick Action Page**: Dedicated `show` page for marking income as received (template-based only)
3. **Swipe Gestures**: Unreceived events can be swiped to reveal "Mark as received" action (on Money Map)
4. **Swipe-Back Navigation**: Swipe right from anywhere on show/edit pages to navigate back
   - Uses `swipe_back_controller.js` Stimulus controller
   - Works from anywhere on page (not just left edge)
   - Doesn't interfere with buttons, links, or form inputs
5. **Expected vs Actual Display**: Visual comparison of expected and received amounts
6. **Mobile-First Design**: Optimized for touch interactions with appropriate button sizes
7. **Navigation Context**: Seamless return to Money Map after actions with scroll-to-section
8. **Turbo Integration**: All navigation uses Turbo for fast, app-like transitions

---

**Last Updated**: December 2025

**Recent Changes (December 2025)**:
- Unified income creation form for one-off and recurring income
- Added `mark_received` and `reset_to_expected` actions
- Removed `toggle_defer` action (deferral functionality removed)
- Added `return_to` parameter support for navigation context
- Auto-fill `actual_amount` logic based on `received_on` date
- Swipe-back navigation on edit form
- Expected vs actual amount comparison in edit form

