# Willow Database ER Diagram

This document contains the Entity-Relationship (ER) diagram for the Willow application database schema.

## Mermaid ER Diagram

```mermaid
erDiagram
    users {
        bigint id PK
        string email UK "NOT NULL, Unique"
        string encrypted_password "NOT NULL"
        string reset_password_token UK "Unique"
        datetime reset_password_sent_at
        datetime remember_created_at
        string display_name
        boolean admin "default: false, NOT NULL"
        datetime created_at
        datetime updated_at
    }

    incomes {
        bigint id PK
        bigint user_id FK "NOT NULL"
        string name "NOT NULL"
        string frequency "default: 'monthly', NOT NULL"
        decimal estimated_amount "precision: 12, scale: 2, default: 0.0"
        boolean active "default: true, NOT NULL"
        boolean auto_create "default: false, NOT NULL"
        integer auto_day_of_month
        datetime created_at
        datetime updated_at
    }

    income_events {
        bigint id PK
        bigint user_id FK "NOT NULL"
        bigint income_id FK "nullable"
        string custom_label
        string month_year "NOT NULL"
        string assigned_month_year
        date received_on "NOT NULL"
        decimal actual_amount "precision: 12, scale: 2, default: 0.0"
        text notes
        datetime created_at
        datetime updated_at
    }

    monthly_budgets {
        bigint id PK
        bigint user_id FK "NOT NULL"
        string month_year "NOT NULL, Format: YYYY-MM"
        decimal total_actual_income "precision: 12, scale: 2, default: 0.0"
        decimal flex_fund "precision: 12, scale: 2, default: 0.0"
        decimal bank_balance "precision: 12, scale: 2, nullable"
        datetime created_at
        datetime updated_at
    }

    expense_templates {
        bigint id PK
        bigint user_id FK "NOT NULL"
        string name "NOT NULL"
        string frequency "default: 'monthly', NOT NULL"
        date due_date "nullable"
        decimal default_amount "precision: 12, scale: 2, default: 0.0"
        boolean auto_create "default: true, NOT NULL"
        boolean is_active "default: true, NOT NULL, soft delete"
        datetime created_at
        datetime updated_at
    }

    expense {
        bigint id PK
        bigint monthly_budget_id FK "NOT NULL"
        bigint expense_template_id FK "NOT NULL"
        decimal allotted_amount "precision: 12, scale: 2, default: 0.0, NOT NULL"
        string name "nullable, override field - uses template name if null"
        datetime created_at
        datetime updated_at
    }

    payments {
        bigint id PK
        bigint expense_id FK "NOT NULL"
        decimal amount "precision: 12, scale: 2, default: 0.0, NOT NULL"
        date spent_on "NOT NULL"
        text notes
        datetime created_at
        datetime updated_at
    }

    %% Relationships
    users ||--o{ incomes : "has many"
    users ||--o{ income_events : "has many"
    users ||--o{ monthly_budgets : "has many"
    users ||--o{ expense_templates : "has many"

    incomes ||--o{ income_events : "has many (optional)"
    
    monthly_budgets ||--o{ expense : "has many"
    
    expense_templates ||--o{ expense : "has many"
    
    expense ||--o{ payments : "has many"
```

## Relationship Details

### One-to-Many Relationships

1. **users → incomes** (1:N)
   - One user can have many income sources
   - Cascade delete: When a user is deleted, all their incomes are deleted

2. **users → income_events** (1:N)
   - One user can have many income events
   - Cascade delete: When a user is deleted, all their income events are deleted

3. **users → monthly_budgets** (1:N)
   - One user can have many monthly budgets (one per month)
   - Cascade delete: When a user is deleted, all their monthly budgets are deleted
   - Unique constraint: One budget per user per month (`user_id`, `month_year`)

4. **users → expense_templates** (1:N)
   - One user can have many expensetemplates (reusable templates for creating expense)
   - Cascade delete: When a user is deleted, all their expensetemplates are deleted
   - Unique constraint: One template name per user (`user_id`, `name`)

5. **incomes → income_events** (1:N, optional)
   - One income source can have many income events (tracking actual payments)
   - Optional relationship: Income events can exist without being linked to an income source
   - Cascade delete: When an income is deleted, all related income events are deleted

6. **monthly_budgets → expense** (1:N)
   - One monthly budget can have many expense (payment categories for that month)
   - Cascade delete: When a monthly budget is deleted, all its expense are deleted
   - Unique constraint: One expenseper template per budget (`monthly_budget_id`, `expense_template_id`), unless name override is used

7. **expense_templates → expense** (1:N)
   - One expensetemplate can be used in many expense (across different monthly budgets)
   - Templates provide default values (name, frequency, due_date, default_amount)
   - Expense can override template name on a per-month basis
   - Cascade delete: When an expensetemplate is deleted, all related expense are deleted

8. **expense → payments** (1:N)
   - One expensecan have many payment records (tracking individual transactions)
   - Cascade delete: When an expenseis deleted, all its payment records are deleted

## Unique Constraints

1. **users.email** - Unique email addresses
2. **users.reset_password_token** - Unique reset tokens
3. **incomes(user_id, name)** - Unique income name per user
4. **monthly_budgets(user_id, month_year)** - One budget per user per month
5. **expense_templates(user_id, name)** - Unique template name per user
6. **expense(monthly_budget_id, expense_template_id)** - One expenseper template per budget (unless name override is used)
7. **expense(monthly_budget_id, name)** - Unique name per budget when using name override

## Override Fields

Expense support override fields that allow customization per month:
- **name** (nullable): If set, overrides the template name for this expense

When override fields are `NULL`, the expense uses the values from its associated `expense_template`. Frequency and due_date always come from the template and cannot be overridden.

## Calculated Fields (Not in Database)

These fields are calculated at the model level and are not stored in the database:

- **expense.spent_amount** - Calculated as `payments.sum(:amount)` for that expense
- **expense.name** - Uses override if present, otherwise delegates to `expense_template.name`
- **expense.frequency** - Always delegates to `expense_template.frequency`
- **expense.due_date** - Always delegates to `expense_template.due_date`

## Notes

- All foreign keys use `on_delete: :cascade`, meaning child records are automatically deleted when parent records are deleted
- All tables include `created_at` and `updated_at` timestamps (managed by Rails)
- Decimal fields use `precision: 12, scale: 2` for currency values
- The `frequency` field in `expense_templates` can be: "monthly", "weekly", "biweekly", or "yearly"
- Expensetemplates serve as reusable templates for creating expense across multiple monthly budgets
- Expense can override template name to customize behavior for specific months

---

**Last Updated**: December 2025
