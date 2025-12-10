# Bill Payment Model Documentation

## Overview

The BillPayment model represents individual payments made for fixed expenses (bills) within an envelope in the Willow application. Bill payments are associated with envelopes that have `group_type: fixed` (like rent, utilities, subscriptions). Each bill payment records the actual amount paid, when it was paid, and any relevant notes.

## Database Table

**Table Name:** `bill_payments`

### Schema

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | Primary Key | Auto-incrementing unique identifier |
| `envelope_id` | bigint | NOT NULL, Foreign Key | References the envelope this payment belongs to |
| `actual_paid_amount` | decimal(12,2) | NOT NULL, Default: 0.0 | The actual amount paid for this bill |
| `paid_on` | date | NOT NULL | The date the bill was paid |
| `notes` | text | Nullable | Optional notes about this payment |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Last update timestamp |

### Indexes

- **Envelope ID + Paid On Index**: Composite index on `[envelope_id, paid_on]` - optimized for finding payments by envelope and date

### Foreign Keys

- `bill_payments.envelope_id` references `envelopes.id` with `on_delete: :cascade`. If an envelope is deleted, all its associated bill payments are deleted.

## Model Location

`app/models/bill_payment.rb`

## Associations

### Belongs To

- **Envelope**: Each bill payment belongs to exactly one envelope
  ```ruby
  bill_payment.envelope  # Returns the Envelope object
  ```

### Has One (through Envelope)

- **MonthlyBudget**: A bill payment indirectly belongs to a monthly budget through its envelope
  ```ruby
  bill_payment.monthly_budget  # Returns the MonthlyBudget object
  ```

- **User**: A bill payment indirectly belongs to a user through its envelope and monthly budget
  ```ruby
  bill_payment.user  # Returns the User object
  ```

### Has Many (from Envelope)

- **Envelope has_many :bill_payments**: An envelope can have multiple bill payments
  ```ruby
  envelope.bill_payments  # Returns a collection of BillPayment objects
  ```
  - **Dependent Behavior**: `destroy` - when an envelope is deleted, all associated bill payments are deleted

## Validations

### Presence Validations

- `validates :actual_paid_amount, presence: true`:
  - The `actual_paid_amount` field must be present.

- `validates :paid_on, presence: true`:
  - The `paid_on` field must be present.

### Numericality Validations

- `validates :actual_paid_amount, numericality: { greater_than: 0, message: "must be greater than 0" }`:
  - `actual_paid_amount` must be a number.
  - `actual_paid_amount` must be greater than 0 (cannot be zero or negative).

### Association Validations

- Requires `envelope` (validated by `belongs_to :envelope`)

## Scopes

- `scope :recent, -> { order(paid_on: :desc, created_at: :desc) }`:
  - Returns bill payments ordered by payment date (most recent first), then by creation date.
  
- `scope :for_date, ->(date) { where(paid_on: date) }`:
  - Returns bill payments paid on a specific date.
  
- `scope :for_date_range, ->(start_date, end_date) { where(paid_on: start_date..end_date) }`:
  - Returns bill payments paid within a date range.
  
- `scope :for_envelope, ->(envelope) { where(envelope: envelope) }`:
  - Returns bill payments for a specific envelope.

## Instance Methods

- `spending_group_name`: Returns the `spending_group_name` from the associated envelope (delegated method for convenience).

- `formatted_amount`: Returns the `actual_paid_amount` formatted as currency (e.g., "$1,200.00").
  
- `today?`: Returns `true` if the payment was made today.
  
- `this_week?`: Returns `true` if the payment was made this week.
  
- `this_month?`: Returns `true` if the payment was made this month.

## Business Rules

1. **Required Associations**: Every bill payment must have an envelope.

2. **Fixed Expenses Only**: Bill payments are typically associated with envelopes that have `group_type: fixed` (fixed/recurring bills), though the model itself doesn't enforce this restriction.

3. **spending_group_name Access**: The `spending_group_name` is accessed through the `envelope` association using a delegated method. This ensures the name always matches the current envelope name and avoids denormalization issues.

4. **Positive Amounts Only**: Bill payment amounts must be greater than 0.

5. **Cascade Deletion**: 
   - Deleting an envelope deletes all its associated bill payments
   - This maintains data integrity and prevents orphaned records

## Usage Examples

### Creating a Bill Payment

```ruby
envelope = Envelope.find_by(spending_group_name: "Rent")
bill_payment = BillPayment.create!(
  envelope: envelope,
  actual_paid_amount: 1200.00,
  paid_on: Date.today,
  notes: "Monthly rent payment"
)

# Access spending_group_name through the envelope
bill_payment.spending_group_name  # => "Rent" (from envelope)
```

### Querying Bill Payments

```ruby
# All payments for an envelope
envelope = Envelope.first
envelope.bill_payments

# Recent payments
BillPayment.recent.limit(10)

# Payments for a specific date
BillPayment.for_date(Date.today)

# Payments within a date range
BillPayment.for_date_range(Date.today.beginning_of_month, Date.today.end_of_month)

# Payments for a specific envelope
BillPayment.for_envelope(envelope)
```

### Calculating Totals

```ruby
# Total paid for an envelope this month
envelope = Envelope.first
total = envelope.bill_payments
  .where(paid_on: Date.today.beginning_of_month..Date.today.end_of_month)
  .sum(:actual_paid_amount)
```

### Updating Bill Payment

```ruby
bill_payment = BillPayment.find(1)
bill_payment.update(actual_paid_amount: 1250.00, notes: "Updated amount")
```

## Relationship to Other Models

### Envelope

- Bill payments belong to envelopes
- Envelopes with `group_type: fixed` typically have bill payments
- The envelope's `spent_amount` may be updated based on bill payments (implementation detail)

### Monthly Budget

- Bill payments are indirectly related to monthly budgets through envelopes
- Monthly budgets track overall spending through their envelopes

### Variable Spending vs Bill Payments

- **Variable Spending**: For envelopes with `group_type: variable` - tracks individual transactions for flexible spending (groceries, entertainment)
- **Bill Payments**: For envelopes with `group_type: fixed` - tracks individual payments for fixed/recurring bills (rent, utilities, subscriptions)

## Admin Dashboard

Bill payments can be managed through the admin dashboard:
- **View All**: `/admin/bill_payments`
- **View Details**: `/admin/bill_payments/:id`
- **Edit**: `/admin/bill_payments/:id/edit`
- **Create**: `/admin/bill_payments/new`

## Future Enhancements

- **Recurring Payments**: Auto-generate bill payments based on frequency
- **Payment Reminders**: Alert users when bills are due
- **Payment History**: Track payment trends over time
- **Attachments**: Allow uploading receipts or payment confirmations
- **Categories**: Additional categorization beyond spending_group_name
- **Payment Methods**: Track how bills were paid (check, credit card, etc.)

---

**Last Updated**: December 2025

