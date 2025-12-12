# Admin::EnvelopesController Documentation

## Overview

The `Admin::EnvelopesController` provides full CRUD (Create, Read, Update, Delete) functionality for managing envelopes in the admin interface. Envelopes represent spending categories within monthly budgets.

## Location

`app/controllers/admin/envelopes_controller.rb`

## Inheritance

- Inherits from `Admin::BaseController`
- Requires authentication and admin privileges

## Routes

All routes are namespaced under `/admin/envelopes`:

- **GET** `/admin/envelopes` - List all envelopes (index)
- **GET** `/admin/envelopes/new` - Show new envelope form
- **POST** `/admin/envelopes` - Create a new envelope
- **GET** `/admin/envelopes/:id` - Show envelope details
- **GET** `/admin/envelopes/:id/edit` - Show edit envelope form
- **PATCH/PUT** `/admin/envelopes/:id` - Update an envelope
- **DELETE** `/admin/envelopes/:id` - Delete an envelope

## Actions

### `index`

Lists all envelopes with pagination and statistics.

**Instance Variables:**
- `@envelopes` - All envelopes, ordered by creation date (newest first), includes `monthly_budget` and `user` associations
- `@total_envelopes` - Total count of all envelopes

**Query Optimization:**
- Uses `includes(monthly_budget: :user)` to eager load associations and prevent N+1 queries

### `show`

Displays detailed information about a specific envelope.

**Instance Variables:**
- `@envelope` - The envelope to display (set by `before_action :set_envelope`)

### `new`

Shows the form to create a new envelope.

**Instance Variables:**
- `@envelope` - A new, unsaved `Envelope` instance
- `@monthly_budgets` - All monthly budgets, ordered by creation date (newest first), includes `user` association
- `@envelope_templates` - All active envelope templates (ordered alphabetically by name via default_scope), includes `user` association

### `create`

Creates a new envelope from form parameters.

**Success:**
- Redirects to `admin_envelope_path(@envelope)` with success notice: "Envelope was successfully created."

**Failure:**
- Re-renders the `new` template with `:unprocessable_entity` status
- Re-sets `@monthly_budgets` and `@envelope_templates` for the form

### `edit`

Shows the form to edit an existing envelope.

**Instance Variables:**
- `@envelope` - The envelope to edit (set by `before_action :set_envelope`)
- `@monthly_budgets` - All monthly budgets, ordered by creation date (newest first), includes `user` association
- `@envelope_templates` - All active envelope templates (ordered alphabetically by name via default_scope), includes `user` association

### `update`

Updates an existing envelope from form parameters.

**Success:**
- Redirects to `admin_envelope_path(@envelope)` with success notice: "Envelope was successfully updated."

**Failure:**
- Re-renders the `edit` template with `:unprocessable_entity` status
- Re-sets `@monthly_budgets` and `@envelope_templates` for the form

### `destroy`

Deletes an envelope.

**Behavior:**
- Destroys the envelope (cascades to associated spendings)
- Redirects to `admin_envelopes_path` with success notice: "Envelope was successfully deleted."

## Callbacks

### `before_action :set_envelope`

Sets `@envelope` for `show`, `edit`, `update`, and `destroy` actions:

```ruby
def set_envelope
  @envelope = Envelope.find(params[:id])
end
```

## Strong Parameters

### `envelope_params`

Permits the following parameters:

- `monthly_budget_id` - The monthly budget this envelope belongs to
- `envelope_template_id` - The envelope template this envelope is based on
- `allotted_amount` - The amount allocated to this envelope for the month
- `name` - Optional override name (uses template name if not provided)

**Note:** `group_type` and `is_savings` are not permitted as they always come from the template.

## Access Control

- Requires user authentication (`before_action :authenticate_user!` from `Admin::BaseController`)
- Requires admin privileges (`before_action :ensure_admin` from `Admin::BaseController`)

## Related Models

- **Envelope** - The model being managed
- **MonthlyBudget** - Required association for envelopes
- **EnvelopeTemplate** - Required association for envelopes

## Views

- `app/views/admin/envelopes/index.html.erb` - List of all envelopes
- `app/views/admin/envelopes/show.html.erb` - Envelope details
- `app/views/admin/envelopes/new.html.erb` - New envelope form
- `app/views/admin/envelopes/edit.html.erb` - Edit envelope form

## Usage Examples

### Creating an Envelope

```ruby
POST /admin/envelopes
{
  envelope: {
    monthly_budget_id: 1,
    envelope_template_id: 2,
    allotted_amount: 500.00,
    name: "Custom Name"  # Optional
  }
}
```

### Updating an Envelope

```ruby
PATCH /admin/envelopes/1
{
  envelope: {
    allotted_amount: 600.00,
    name: "Updated Name"  # Optional
  }
}
```

---

**Last Updated**: December 2025

