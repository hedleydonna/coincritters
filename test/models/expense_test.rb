require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  setup do
    @monthly_budget_one = monthly_budgets(:one)
    @monthly_budget_two = monthly_budgets(:two)
    @expense_one = expenses(:one)
    @expense_two = expenses(:two)
  end

  test "should be valid with valid attributes" do
    expense_template = ExpenseTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Utilities",
      frequency: "monthly"
    )
    expense = Expense.new(
      monthly_budget: @monthly_budget_one,
      expense_template: expense_template,
      allotted_amount: 150.00
    )
    assert expense.valid?
  end

  test "should require a monthly_budget" do
    expense_template = expense_templates(:one)
    expense = Expense.new(
      expense_template: expense_template
    )
    assert_not expense.valid?
    assert_includes expense.errors[:monthly_budget], "must exist"
  end

  test "should require an expense_template" do
    expense = Expense.new(
      monthly_budget: @monthly_budget_one
    )
    assert_not expense.valid?
    assert_includes expense.errors[:expense_template], "must exist"
  end

  test "should enforce unique expense_template per monthly_budget" do
    expense_template = expense_templates(:one)
    duplicate_expense = Expense.new(
      monthly_budget: @monthly_budget_one,
      expense_template: expense_template
    )
    assert_not duplicate_expense.valid?
    assert_includes duplicate_expense.errors[:expense_template_id], "already has an expense for this template in this budget"
  end

  test "different monthly_budgets can have envelopes with same expense_template" do
    # expense_one uses expense_template one in monthly_budget_one
    # Different budgets can use the same expense template
    assert_equal expense_templates(:one), expenses(:one).expense_template
    assert_equal monthly_budgets(:one), expenses(:one).monthly_budget
    
    # Both expenses are valid even though they share the same expense template (in different budgets)
    assert expenses(:one).valid?
    assert expenses(:four).valid?
  end

  test "should get frequency from expense_template" do
    monthly_template = ExpenseTemplate.create!(
      user: @monthly_budget_two.user,
      name: "Monthly Test Template",
      frequency: "monthly"
    )
    weekly_template = ExpenseTemplate.create!(
      user: @monthly_budget_two.user,
      name: "Weekly Test Template",
      frequency: "weekly"
    )
    
    monthly_expense = Expense.new(
      monthly_budget: @monthly_budget_two,
      expense_template: monthly_template
    )
    assert_equal "monthly", monthly_expense.frequency

    weekly_expense = Expense.new(
      monthly_budget: @monthly_budget_two,
      expense_template: weekly_template
    )
    assert_equal "weekly", weekly_expense.frequency
  end

  test "should get due_date from expense_template" do
    template_with_due_date = ExpenseTemplate.create!(
      user: @monthly_budget_two.user,
      name: "Template With Due Date",
      frequency: "monthly",
      due_date: Date.new(2025, 1, 15)
    )
    
    expense = Expense.new(
      monthly_budget: @monthly_budget_two,
      expense_template: template_with_due_date
    )
    assert_equal Date.new(2025, 1, 15), expense.due_date
  end

  test "should require allotted_amount to be greater than or equal to 0" do
    expense_template = ExpenseTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Test Template",
      frequency: "monthly"
    )
    expense = Expense.new(
      monthly_budget: @monthly_budget_one,
      expense_template: expense_template,
      allotted_amount: -100.00
    )
    assert_not expense.valid?
    assert_includes expense.errors[:allotted_amount], "must be greater than or equal to 0"
  end

  test "should auto-fill allotted_amount from template default_amount when creating" do
    # Create a unique expense template with a default amount
    expense_template = ExpenseTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Auto Fill Test Template",
      frequency: "monthly",
      default_amount: 250.00
    )
    expense = Expense.create!(
      monthly_budget: @monthly_budget_one,
      expense_template: expense_template
    )
    assert_equal 250.00, expense.allotted_amount.to_f
  end

  test "should use 0.0 as default allotted_amount if template default_amount is nil" do
    # Create a unique expense template without a default amount
    expense_template = ExpenseTemplate.create!(
      user: @monthly_budget_one.user,
      name: "No Default Amount Test Template",
      frequency: "monthly",
      default_amount: nil
    )
    expense = Expense.create!(
      monthly_budget: @monthly_budget_one,
      expense_template: expense_template
    )
    assert_equal 0.0, expense.allotted_amount.to_f
  end

  test "should not override explicitly set allotted_amount with default" do
    expense_template = ExpenseTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Explicit Amount Test Template",
      frequency: "monthly",
      default_amount: 100.00
    )
    expense = Expense.create!(
      monthly_budget: @monthly_budget_one,
      expense_template: expense_template,
      allotted_amount: 500.00
    )
    assert_equal 500.00, expense.allotted_amount.to_f
  end

  test "spent_amount should calculate from payments" do
    # expense_one has payments totaling 75.50 + 45.25 + 120.00 = 240.75
    assert_equal 240.75, @expense_one.spent_amount.to_f
    
    # expense_two has payments totaling 1200.00 + 1200.00 = 2400.00
    assert_equal 2400.00, @expense_two.spent_amount.to_f
    
    # expense with no payments should be 0
    assert_equal 0.0, expenses(:three).spent_amount.to_f
  end

  test "should destroy when monthly_budget is destroyed" do
    budget = MonthlyBudget.create!(
      user: users(:one),
      month_year: "2026-03"
    )
    expense_template = ExpenseTemplate.create!(
      user: users(:one),
      name: "Test Template",
      frequency: "monthly"
    )
    expense = Expense.create!(
      monthly_budget: budget,
      expense_template: expense_template
    )
    
    assert_difference("Expense.count", -1) do
      budget.destroy
    end
  end

  test "by_frequency scope should return only expenses with specific frequency" do
    monthly_template = ExpenseTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Monthly Template",
      frequency: "monthly"
    )
    weekly_template = ExpenseTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Weekly Template",
      frequency: "weekly"
    )
    
    monthly_expense = Expense.create!(
      monthly_budget: @monthly_budget_one,
      expense_template: monthly_template
    )
    weekly_expense = Expense.create!(
      monthly_budget: @monthly_budget_one,
      expense_template: weekly_template
    )
    
    monthly_expenses = Expense.by_frequency("monthly")
    assert_includes monthly_expenses, monthly_expense
    assert_not_includes monthly_expenses, weekly_expense
  end

  test "over_budget scope should return only expenses where spent exceeds allotted" do
    # expense_two is over budget (spent 2400 > allotted 1200)
    over_budget_expenses = Expense.over_budget
    assert_includes over_budget_expenses, @expense_two
    assert_not_includes over_budget_expenses, @expense_one
  end

  test "frequency_text should return correct text" do
    monthly_template = ExpenseTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Monthly Template",
      frequency: "monthly"
    )
    expense = Expense.create!(
      monthly_budget: @monthly_budget_one,
      expense_template: monthly_template
    )
    assert_equal "Monthly", expense.frequency_text
  end

  test "should destroy when expense_template is destroyed" do
    expense_template = ExpenseTemplate.create!(
      user: users(:one),
      name: "Test Template For Deletion"
    )
    expense = Expense.create!(
      monthly_budget: @monthly_budget_one,
      expense_template: expense_template
    )
    
    assert_difference("Expense.count", -1) do
      expense_template.destroy
    end
  end

  test "remaining should calculate allotted minus spent" do
    # expense_one: allotted 500.00, spent 240.75 (from payments), remaining 259.25
    assert_equal 259.25, @expense_one.remaining.to_f
    # expense_two: allotted 1200.00, spent 2400.00 (from payments), remaining -1200.00
    assert_equal -1200.00, @expense_two.remaining.to_f
  end

  test "available should return remaining or 0, whichever is higher" do
    # expense_one: remaining 259.25
    assert_equal 259.25, @expense_one.available.to_f
    
    # Create an envelope that's over budget
    expense_template = ExpenseTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Over Budget Test Template",
      frequency: "monthly"
    )
    over_budget_expense = Expense.create!(
      monthly_budget: @monthly_budget_one,
      expense_template: expense_template,
      allotted_amount: 100.00
    )
    Payment.create!(
      expense: over_budget_expense,
      amount: 150.00,
      spent_on: Date.today
    )
    assert_equal 0.0, over_budget_expense.available.to_f
  end

  test "over_budget? should return true when spent exceeds allotted" do
    # expense_two is over budget (spent 2400 > allotted 1200)
    assert @expense_two.over_budget?
    # expense_one is not over budget (spent 240.75 < allotted 500)
    assert_not @expense_one.over_budget?
  end

  test "spent_percentage should calculate percentage correctly" do
    # expense_one: 240.75 / 500.00 = 48.15%
    assert_equal 48.2, @expense_one.spent_percentage
    # expense_two: 2400.00 / 1200.00 = 200%, capped at 100%
    assert_equal 100.0, @expense_two.spent_percentage
    
    expense_template = ExpenseTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Empty Test Template",
      frequency: "monthly"
    )
    empty_expense = Expense.create!(
      monthly_budget: @monthly_budget_one,
      expense_template: expense_template,
      allotted_amount: 0.00
    )
    assert_equal 0, empty_expense.spent_percentage
    
    # Test with negative allotted_amount (edge case - shouldn't happen but safer)
    negative_expense = Expense.new(
      monthly_budget: @monthly_budget_one,
      expense_template: expense_template,
      allotted_amount: -100.00
    )
    assert_equal 0, negative_expense.spent_percentage
  end

  test "spent_percentage should cap at 100" do
    # expense_two already exceeds 100% so it should be capped
    assert_equal 100.0, @expense_two.spent_percentage
  end

  test "paid? should return true for fixed expenses when spent >= allotted" do
    # Create a fixed template
    fixed_template = ExpenseTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Fixed Bill Test",
      frequency: "monthly"
    )
    
    # Create envelope with allotted amount
    fixed_expense = Expense.create!(
      monthly_budget: @monthly_budget_one,
      expense_template: fixed_template,
      allotted_amount: 1000.00
    )
    
    # Not paid yet
    assert_not fixed_expense.paid?
    
    # Add payment that equals allotted amount
    Payment.create!(
      expense: fixed_expense,
      amount: 1000.00,
      spent_on: Date.today
    )
    assert fixed_expense.paid?
    
    # Add more payment (over paid)
    Payment.create!(
      expense: fixed_expense,
      amount: 100.00,
      spent_on: Date.today
    )
    assert fixed_expense.paid?
  end

  test "paid? should return true when spent >= allotted" do
    # Create a new template to avoid uniqueness constraint
    template = ExpenseTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Test Paid Template",
      frequency: "monthly"
    )
    
    expense = Expense.create!(
      monthly_budget: @monthly_budget_one,
      expense_template: template,
      allotted_amount: 500.00
    )
    
    # Add payment that equals allotted
    Payment.create!(
      expense: expense,
      amount: 500.00,
      spent_on: Date.today
    )
    
    # Expense is paid when spent >= allotted
    assert expense.paid?
    
    # Add more payment
    Payment.create!(
      expense: expense,
      amount: 100.00,
      spent_on: Date.today
    )
    
    # Still paid when spent > allotted
    assert expense.paid?
  end

  test "to_s should return friendly string with name and budget" do
    expense = @expense_one
    to_s_string = expense.to_s
    assert_match(/#{expense.name}/, to_s_string)
    assert_match(/#{expense.monthly_budget.name}/, to_s_string)
  end

  test "name should use expense_template name by default" do
    expense = @expense_one
    assert_equal expense.expense_template.name, expense.name
  end

  test "name should use override when provided" do
    expense_template = ExpenseTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Template Name",
      frequency: "monthly"
    )
    expense = Expense.create!(
      monthly_budget: @monthly_budget_one,
      expense_template: expense_template,
      name: "Custom Override Name"
    )
    assert_equal "Custom Override Name", expense.name
    assert expense.name_overridden?
  end

  test "display_name should use expense_template or override" do
    expense = @expense_one
    assert_equal expense.expense_template.display_name, expense.display_name
  end

  test "display_name should return the expense name" do
    expense = expenses(:one)
    assert_equal expense.name, expense.display_name
  end

  test "percent_used should return integer percentage" do
    # expense_one: 240.75 / 500.00 = 48.15%, rounded to 48
    assert_equal 48, @expense_one.percent_used
    
    # expense_two: 2400.00 / 1200.00 = 200%, rounded to 200
    assert_equal 200, @expense_two.percent_used
    
    # Empty envelope
    expense_template = ExpenseTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Empty Percent Test",
      frequency: "monthly"
    )
    empty_expense = Expense.create!(
      monthly_budget: @monthly_budget_one,
      expense_template: expense_template,
      allotted_amount: 0.00
    )
    assert_equal 0, empty_expense.percent_used
  end
end

