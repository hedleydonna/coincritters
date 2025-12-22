# MoneyMapController Documentation

## Overview

The `MoneyMapController` provides the main dashboard view for users after login. It displays a comprehensive overview of the current month's financial situation, including income events, expenses, progress indicators, and a "Bottom Line" summary. This is the primary landing page for authenticated users.

## Location

`app/controllers/money_map_controller.rb`

## Inheritance

- Inherits from `ApplicationController`
- Requires authentication (`before_action :authenticate_user!`)

## Routes

- **GET** `/money_map` - View Money Map overview (main dashboard)
- **GET** `/money_map?scroll_to=spending-section` - View Money Map and scroll to specific section

## Actions

### `index`

The main Money Map overview page. This is the default landing page after user login.

**Auto-Creation Behavior:**
- Automatically creates current month budget if missing
- Always regenerates income events from active templates when viewing
- Always regenerates expenses from active templates when viewing
- Auto-fills `actual_amount` for income events where `received_on` date has passed and `actual_amount` is 0

**Auto-Fill Logic:**
- Finds income events where:
  - `received_on <= Date.today`
  - `actual_amount == 0`
  - Has an associated template with `estimated_amount > 0`
- Sets `actual_amount` to `estimated_amount` for these events
- Uses `update_column` to bypass validations (direct database update)

**Instance Variables:**
- `@budget` - Current month's monthly budget
- `@total_income` - Total actual income received (`total_actual_income`)
- `@available_income` - Available income including carryover (`available_income`)
- `@carryover` - Carryover amount from previous month (`carryover_from_previous_month`)
- `@expected_income` - Expected income for the month (`expected_income`)
- `@total_spent` - Total spent across all expenses (`total_spent`)
- `@total_allotted` - Total allotted across all expenses (`total_allotted`)
- `@remaining` - Remaining money (`available_income - total_spent`)
- `@remaining_to_assign` - Remaining to assign (`remaining_to_assign`)
- `@income_events` - All income events for current month, ordered by `received_on`
- `@expenses` - All expenses for current month, ordered by `expected_on`, `due_date`, then `name`
- `@viewing_month` - Current month string (YYYY-MM)
- `@month_name` - Human-readable month name (e.g., "December 2025")

**Income Events Query:**
- Filters out events from deleted templates
- Includes one-off events (no template)
- Orders by `received_on` date

**Expenses Query:**
- Filters out expenses from deleted templates
- Includes one-off expenses (no template)
- Orders by `expected_on` (for weekly/bi-weekly), then `due_date` (for template-based), then `name`
- Uses `includes(:expense_template)` to avoid N+1 queries

**Error Handling:**
- Wraps entire action in rescue block
- On error, sets all variables to safe defaults (0 or empty arrays)
- Logs error for debugging

## View Features

The Money Map view (`app/views/money_map/index.html.erb`) includes:

1. **Overview Section:**
   - Month name display
   - "Bottom Line" section showing "Money Left This Month" with progress bar
   - Income progress bar: "Received/Expected" with percentage
   - Spending progress bar: "Spent/Allotted" with percentage

2. **Money In Section:**
   - Lists all income events for current month
   - Grouped by `received_on` date (default) or by status (Received/Expected)
   - Toggle between date view and status view
   - Visual distinction for one-off income events (blue background)
   - Clickable items that link to edit form
   - Shows expected vs received amounts
   - Swipe-to-mark-received functionality
   - "Create Source" link to new income form
   - "Group by Status" toggle button

3. **Spending Section:**
   - Lists all expenses for current month
   - Grouped by `expected_on` date (default) or by status (Paid/Remaining)
   - Toggle between date view and status view
   - Visual distinction for one-off expenses
   - Clickable items that link to edit form
   - Shows allotted vs spent amounts
   - "Create Spending" link to new expense form
   - "Group by Status" toggle button

4. **Navigation:**
   - Scroll-to-anchor functionality for deep linking
   - `return_to` parameter support for seamless navigation

## Scroll-to-Anchor Functionality

The view supports scrolling to specific sections after navigation:
- Uses `scroll_to` query parameter (e.g., `?scroll_to=money-in-section`)
- Stimulus controller (`scroll_to_anchor_controller.js`) handles scrolling within fixed container
- Cleans up URL after scrolling
- Works seamlessly with Turbo navigation
- Uses multiple timing strategies to prevent visible "scroll to top then scroll down" jumps
- Scrolls instantly (no smooth animation) to avoid visible movement

**Implementation Details:**
- Listens to `turbo:load`, `turbo:before-render`, and `turbo:render` events
- Tries scrolling at multiple points: immediate, microtask, requestAnimationFrame, setTimeout
- Uses flags to prevent duplicate scrolls
- Properly cleans up event listeners to prevent memory leaks

**Sections:**
- `money-in-section` - Scrolls to Money In section
- `spending-section` - Scrolls to Spending section

## Business Rules

1. **Current Month Only**: Only displays current month data
2. **Auto-Creation**: Always ensures income events and expenses are up-to-date
3. **Auto-Fill**: Automatically fills `actual_amount` for past-due income events
4. **Filtering**: Excludes items from deleted templates
5. **Ordering**: Income events by date, expenses by expected date then name

## Related Models

- **MonthlyBudget** - Current month's budget
- **IncomeEvent** - Income events for the month
- **Expense** - Expenses for the month
- **IncomeTemplate** - Templates for income events
- **ExpenseTemplate** - Templates for expenses

## Views

- `app/views/money_map/index.html.erb` - Main Money Map overview page

## Usage Examples

### Viewing Money Map

```ruby
GET /money_map
# Shows current month overview
```

### Viewing Money Map with Scroll

```ruby
GET /money_map?scroll_to=spending-section
# Shows Money Map and scrolls to spending section
```

## Key Features

1. **Complete Overview**: Single page showing all financial information
2. **Progress Indicators**: Visual progress bars for income and spending
3. **Bottom Line**: Prominent display of money left this month
4. **Grouping Options**: Toggle between date-based and status-based grouping
5. **Quick Actions**: Direct links to create income/expenses
6. **Auto-Updates**: Automatically ensures data is current when viewing
7. **Mobile-Optimized**: Responsive design with touch-friendly interactions

---

**Last Updated**: December 2025

