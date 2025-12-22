require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  setup do
    @expense_one = expenses(:one)
    @expense_two = expenses(:two)
    @payment_one = payments(:one)
    @payment_two = payments(:two)
  end

  test "should be valid with valid attributes" do
    payment = Payment.new(
      expense: @expense_one,
      amount: 50.00,
      spent_on: Date.current
    )
    assert payment.valid?
  end

  test "should require an expense" do
    payment = Payment.new(
      amount: 50.00,
      spent_on: Date.current
    )
    assert_not payment.valid?
    assert_includes payment.errors[:expense], "must exist"
  end

  test "spending_group_name should return expense's spending_group_name" do
    payment = Payment.new(
      expense: @expense_one,
      amount: 50.00,
      spent_on: Date.current
    )
    assert_equal @expense_one.spending_group_name, payment.spending_group_name
  end

  test "should require amount to be greater than 0" do
    payment_zero = Payment.new(
      expense: @expense_one,
      amount: 0.0,
      spent_on: Date.current
    )
    assert_not payment_zero.valid?
    assert_includes payment_zero.errors[:amount], "must be greater than 0"

    payment_negative = Payment.new(
      expense: @expense_one,
      amount: -10.00,
      spent_on: Date.current
    )
    assert_not payment_negative.valid?
    assert_includes payment_negative.errors[:amount], "must be greater than 0"
  end

  test "should require spent_on" do
    payment = Payment.new(
      expense: @expense_one,
      amount: 1200.00
    )
    assert_not payment.valid?
    assert_includes payment.errors[:spent_on], "can't be blank"
  end

  test "should allow notes to be blank" do
    payment = Payment.new(
      expense: @expense_one,
      amount: 1200.00,
      spent_on: Date.current,
      notes: nil
    )
    assert payment.valid?
  end

  test "should destroy when expense is destroyed" do
    expense_template = ExpenseTemplate.create!(
      user: users(:one),
      name: "Test ExpenseTemplate",
      frequency: "monthly"
    )
    expense = Expense.create!(
      monthly_budget: monthly_budgets(:one),
      expense_template: expense_template,
      name: expense_template.name
    )
    payment = Payment.create!(
      expense: expense,
      amount: 100.00,
      spent_on: Date.current
    )
    
    assert_difference("Payment.count", -1) do
      expense.destroy
    end
  end

  test "recent scope should return records ordered by spent_on desc and created_at desc" do
    expense = expenses(:two)
    s1 = Payment.create!(expense: expense, amount: 10, spent_on: Date.current - 2.days, created_at: 2.days.ago)
    s2 = Payment.create!(expense: expense, amount: 20, spent_on: Date.current - 1.day, created_at: 1.day.ago)
    s3 = Payment.create!(expense: expense, amount: 30, spent_on: Date.current - 1.day, created_at: 3.days.ago)

    # Scope to just the records we created to avoid fixture interference
    recent_payments = Payment.where(id: [s1.id, s2.id, s3.id]).recent.to_a
    
    assert_equal s2, recent_payments[0]
    assert_equal s3, recent_payments[1]
    assert_equal s1, recent_payments[2]
  end

  test "for_date scope should return records for specific date" do
    date = Date.parse("2025-12-01")
    payments_on_date = Payment.for_date(date)
    assert_includes payments_on_date, payments(:four)
    payments_on_date.each do |payment|
      assert_equal date, payment.spent_on
    end
  end

  test "for_date_range scope should return records within date range" do
    start_date = Date.parse("2025-12-01")
    end_date = Date.parse("2025-12-15")
    payments_in_range = Payment.for_date_range(start_date, end_date)
    assert_includes payments_in_range, payments(:one)
    assert_includes payments_in_range, payments(:four)
    payments_in_range.each do |payment|
      assert payment.spent_on >= start_date && payment.spent_on <= end_date
    end
  end

  test "for_expense scope should return records for specific expense" do
    expense_payments = Payment.for_expense(@expense_one)
    assert_includes expense_payments, @payment_one
    assert_includes expense_payments, @payment_two
    expense_payments.each do |payment|
      assert_equal @expense_one, payment.expense
    end
  end

  test "formatted_amount should return formatted currency string" do
    payment = Payment.new(amount: 123.456)
    # number_to_currency formats with 2 decimal places
    assert_match(/\$123\.46/, payment.formatted_amount)
  end

  test "today? should return true if spent_on is today" do
    today_payment = Payment.new(
      expense: @expense_one,
      amount: 100.00,
      spent_on: Date.current
    )
    assert today_payment.today?
    
    unless 1.day.ago.to_date == Date.current
      yesterday_payment = Payment.new(
        expense: @expense_one,
        amount: 100.00,
        spent_on: 1.day.ago.to_date
      )
      assert_not yesterday_payment.today?
    end
  end

  test "this_week? should return true if spent_on is this week" do
    this_week_payment = Payment.new(
      expense: @expense_one,
      amount: 100.00,
      spent_on: Date.current
    )
    assert this_week_payment.this_week?
    
    last_week_payment = Payment.new(
      expense: @expense_one,
      amount: 100.00,
      spent_on: 2.weeks.ago.to_date
    )
    assert_not last_week_payment.this_week?
  end

  test "this_month? should return true if spent_on is this month" do
    this_month_payment = Payment.new(
      expense: @expense_one,
      amount: 100.00,
      spent_on: Date.current
    )
    assert this_month_payment.this_month?
    
    last_month_payment = Payment.new(
      expense: @expense_one,
      amount: 100.00,
      spent_on: 2.months.ago.to_date
    )
    assert_not last_month_payment.this_month?
  end

  test "to_s should return friendly string with formatted amount and date" do
    payment = Payment.create!(
      expense: @expense_one,
      amount: 75.50,
      spent_on: Date.parse("2025-12-15")
    )
    to_s_string = payment.to_s
    assert_match(/\$75\.50/, to_s_string)
    assert_match(/December 15, 2025/, to_s_string)
    assert_match(/#{payment.spending_group_name}/, to_s_string)
  end

  test "should access monthly_budget through expense" do
    assert_equal @expense_one.monthly_budget, @payment_one.monthly_budget
  end

  test "should access user through monthly_budget" do
    assert_equal @expense_one.user, @payment_one.user
  end
end

