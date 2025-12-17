# IncomeEventsController Documentation

## Overview

The `IncomeEventsController` provides functionality for users to view and manage income events. It supports viewing current and next month, creating one-off income events, editing auto-created events, and managing income deferral.

## Location

`app/controllers/income_events_controller.rb`

## Inheritance

- Inherits from `ApplicationController`
- Requires authentication (`before_action :authenticate_user!`)

## Routes

All routes are under `/income_events`:
- **GET** `/income_events` - View income events (current month by default)
- **GET** `/income_events?month=YYYY-MM` - View income events for specific month (current or next only)
- **GET** `/income_events/new` - Show new one-off income event form
- **POST** `/income_events` - Create a new one-off income event
- **GET** `/income_events/:id/edit` - Edit an income event
- **PATCH** `/income_events/:id` - Update an income event
- **POST** `/income_events/:id/toggle_defer` - Toggle deferral to next month
- **POST** `/income_events/:id/mark_received` - Mark event as received (sets actual_amount to estimated_amount)
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
- **Current month**: Shows events from current month (not deferred) + deferred events from previous month
- **Next month**: Shows events from next month (not deferred) + deferred events from current month

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

Shows the form to create a new one-off income event.

**Behavior:**
- Creates one-off income events (not linked to income templates)
- Sets `income_template_id` to `nil` and `apply_to_next_month` to `false`
- Sets `month_year` from `received_on` date
- Defaults `received_on` to today

**Instance Variables:**
- `@income_event` - New IncomeEvent instance
- `@apply_to_month` - Which month to apply to ("current" or "next")
- `@current_month_str` - Current month string
- `@next_month_str` - Next month string

**Parameters:**
- `income_event_id` (optional) - If provided, redirects to edit that event instead
- `apply_to` (optional) - Which month to apply to ("current" or "next", defaults to "current")

### `create`

Creates a new one-off income event.

**Behavior:**
- Always creates one-off events (no income_template_id)
- Sets `apply_to_next_month` to `false` (one-off income always counts in month received)
- Sets `month_year` from `received_on` date

**Success:**
- Redirects to `income_events_path` with notice showing amount added

**Failure:**
- Re-renders the `new` template with `:unprocessable_entity` status

**Parameters:**
- `income_event[custom_label]` - Label for the income event (required for one-off)
- `income_event[received_on]` - Date income was received
- `income_event[actual_amount]` - Amount received
- `income_event[notes]` - Optional notes

### `edit`

Shows the form to edit an existing income event.

**Instance Variables:**
- `@income_event` - The income event being edited
- `@income_templates` - All active income templates (for template-based events)
- `@income_data` - JSON hash of template IDs to estimated amounts (for JavaScript)

**Parameters:**
- `id` - Income event ID to edit

### `update`

Updates an existing income event.

**Behavior:**
- Updates `month_year` if `received_on` changed
- Allows updating template link, deferral status, and amounts

**Success:**
- Redirects to `income_events_path` with notice showing updated amount

**Failure:**
- Re-renders the `edit` template with `:unprocessable_entity` status

**Parameters:**
- `id` - Income event ID to update
- `income_event[income_template_id]` - Template ID (optional, for template-based events)
- `income_event[custom_label]` - Custom label (for one-off events)
- `income_event[received_on]` - Date received
- `income_event[actual_amount]` - Amount received
- `income_event[apply_to_next_month]` - Whether to defer to next month
- `income_event[notes]` - Optional notes

### `toggle_defer`

Toggles whether an income event counts toward current or next month.

**Behavior:**
- Toggles `apply_to_next_month` boolean
- Updates the monthly budget's total_actual_income automatically

**Success:**
- Redirects to `income_events_path` with notice about new status

**Parameters:**
- `id` - Income event ID to toggle

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
- `custom_label` - Label for one-off income (required)
- `received_on` - Date income was received
- `actual_amount` - Amount received
- `notes` - Optional notes

**For `update` action:**
- `income_template_id` - Template ID (optional)
- `custom_label` - Custom label (for one-off events)
- `received_on` - Date received
- `actual_amount` - Amount received
- `apply_to_next_month` - Whether to defer to next month
- `notes` - Optional notes

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
- `app/views/income_events/new.html.erb` - New one-off income event form
- `app/views/income_events/edit.html.erb` - Edit income event form

## Business Rules

1. **Month Restrictions**: Only current and next month can be viewed
2. **One-Off Events**: New events created through controller are always one-off (no template)
3. **Auto-Creation**: Income events are auto-created from templates when viewing a month
4. **Deferral**: Income can be deferred to next month using `apply_to_next_month`
5. **Budget Updates**: Monthly budget totals update automatically when events change
6. **Deletion Policy**: Only one-off income events can be deleted to prevent auto-recreation conflicts

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

### Toggling Deferral

```ruby
POST /income_events/123/toggle_defer
# Toggles whether income counts in current or next month
```

### Marking as Received

```ruby
POST /income_events/123/mark_received
# Sets actual_amount to template's estimated_amount
```

## UI Features

1. **Icon-Based Actions**: All action buttons (Received, Defer, Edit, Delete) use icons with tooltips
2. **Swipe Gestures**: Unreceived events can be swiped to reveal "Mark as received" action
3. **Mobile-First Design**: Optimized for touch interactions with appropriate button sizes

---

**Last Updated**: January 2026

**Recent Changes (January 2026)**:
- Updated `destroy` action to only allow deletion of one-off income events
- Template-based income events cannot be deleted (prevents auto-recreation conflicts)
- Delete button only appears for one-off income events in the UI

