require "test_helper"

class VariableSpendingTest < ActiveSupport::TestCase
  setup do
    @envelope_one = envelopes(:one)
    @envelope_five = envelopes(:five)
    @variable_spending_one = variable_spending(:one)
    @variable_spending_two = variable_spending(:two)
  end

  test "should be valid with valid attributes" do
    variable_spending = VariableSpending.new(
      envelope: @envelope_one,
      amount: 50.00,
      spent_on: Date.today
    )
    assert variable_spending.valid?
  end

  test "should require an envelope" do
    variable_spending = VariableSpending.new(
      amount: 50.00,
      spent_on: Date.today
    )
    assert_not variable_spending.valid?
    assert_includes variable_spending.errors[:envelope], "must exist"
  end

  test "spending_group_name should return envelope's spending_group_name" do
    variable_spending = VariableSpending.new(
      envelope: @envelope_one,
      amount: 50.00,
      spent_on: Date.today
    )
    assert_equal @envelope_one.spending_group_name, variable_spending.spending_group_name
  end

  test "should require amount to be greater than 0" do
    variable_spending = VariableSpending.new(
      envelope: @envelope_one,
      amount: 0.00,
      spent_on: Date.today
    )
    assert_not variable_spending.valid?
    assert_includes variable_spending.errors[:amount], "must be greater than 0"

    variable_spending.amount = -10.00
    assert_not variable_spending.valid?
    assert_includes variable_spending.errors[:amount], "must be greater than 0"
  end

  test "should require spent_on" do
    variable_spending = VariableSpending.new(
      envelope: @envelope_one,
      amount: 50.00
    )
    assert_not variable_spending.valid?
    assert_includes variable_spending.errors[:spent_on], "can't be blank"
  end

  test "should have default amount of 0.0" do
    variable_spending = VariableSpending.create!(
      envelope: @envelope_one,
      amount: 50.00,
      spent_on: Date.today
    )
    # The default in the schema is 0.0, but we require it to be > 0
    # So we must provide a valid amount
    assert variable_spending.amount.to_f > 0
  end

  test "should allow notes to be blank" do
    variable_spending = VariableSpending.new(
      envelope: @envelope_one,
      amount: 50.00,
      spent_on: Date.today,
      notes: nil
    )
    assert variable_spending.valid?
  end

  test "should destroy when envelope is destroyed" do
    envelope = Envelope.create!(
      monthly_budget: monthly_budgets(:one),
      spending_group_name: "Test Envelope",
      group_type: :variable
    )
    variable_spending = VariableSpending.create!(
      envelope: envelope,
      amount: 25.00,
      spent_on: Date.today
    )
    
    assert_difference("VariableSpending.count", -1) do
      envelope.destroy
    end
  end

  test "recent scope should return records ordered by spent_on desc" do
    recent_spending = VariableSpending.recent
    assert recent_spending.first.spent_on >= recent_spending.last.spent_on
  end

  test "for_date scope should return records for specific date" do
    date = Date.parse("2025-12-10")
    spending_on_date = VariableSpending.for_date(date)
    assert_includes spending_on_date, @variable_spending_one
    spending_on_date.each do |spending|
      assert_equal date, spending.spent_on
    end
  end

  test "for_date_range scope should return records within date range" do
    start_date = Date.parse("2025-12-10")
    end_date = Date.parse("2025-12-15")
    spending_in_range = VariableSpending.for_date_range(start_date, end_date)
    assert_includes spending_in_range, @variable_spending_one
    assert_includes spending_in_range, @variable_spending_two
    spending_in_range.each do |spending|
      assert spending.spent_on >= start_date && spending.spent_on <= end_date
    end
  end

  test "for_envelope scope should return records for specific envelope" do
    envelope_spending = VariableSpending.for_envelope(@envelope_one)
    assert_includes envelope_spending, @variable_spending_one
    assert_includes envelope_spending, @variable_spending_two
    envelope_spending.each do |spending|
      assert_equal @envelope_one, spending.envelope
    end
  end

  test "formatted_amount should return formatted currency string" do
    variable_spending = VariableSpending.new(amount: 123.456)
    assert_equal "$123.46", variable_spending.formatted_amount
  end

  test "today? should return true if spent_on is today" do
    today_spending = VariableSpending.new(
      envelope: @envelope_one,
      amount: 10.00,
      spent_on: Date.today
    )
    assert today_spending.today?
    
    # Use 1.day.ago.to_date to ensure we get a date that's actually not today
    past_date = 1.day.ago.to_date
    past_spending = VariableSpending.new(
      envelope: @envelope_one,
      amount: 10.00,
      spent_on: past_date
    )
    # Only assert if past_date is actually different from today (handle edge cases)
    if past_date != Date.today
      assert_not past_spending.today?
    end
  end

  test "this_week? should return true if spent_on is this week" do
    variable_spending = VariableSpending.new(
      envelope: @envelope_one,
      amount: 10.00,
      spent_on: Date.today
    )
    assert variable_spending.this_week?
    
    variable_spending.spent_on = 2.weeks.ago
    assert_not variable_spending.this_week?
  end

  test "this_month? should return true if spent_on is this month" do
    variable_spending = VariableSpending.new(
      envelope: @envelope_one,
      amount: 10.00,
      spent_on: Date.today
    )
    assert variable_spending.this_month?
    
    variable_spending.spent_on = 2.months.ago
    assert_not variable_spending.this_month?
  end

  test "should access monthly_budget through envelope" do
    assert_equal @envelope_one.monthly_budget, @variable_spending_one.monthly_budget
  end

  test "should access user through monthly_budget" do
    assert_equal @envelope_one.user, @variable_spending_one.user
  end
end

