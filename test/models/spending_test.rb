require "test_helper"

class SpendingTest < ActiveSupport::TestCase
  setup do
    @envelope_one = envelopes(:one)
    @envelope_two = envelopes(:two)
    @spending_one = spendings(:one)
    @spending_two = spendings(:two)
  end

  test "should be valid with valid attributes" do
    spending = Spending.new(
      envelope: @envelope_one,
      amount: 50.00,
      spent_on: Date.today
    )
    assert spending.valid?
  end

  test "should require an envelope" do
    spending = Spending.new(
      amount: 50.00,
      spent_on: Date.today
    )
    assert_not spending.valid?
    assert_includes spending.errors[:envelope], "must exist"
  end

  test "spending_group_name should return envelope's spending_group_name" do
    spending = Spending.new(
      envelope: @envelope_one,
      amount: 50.00,
      spent_on: Date.today
    )
    assert_equal @envelope_one.spending_group_name, spending.spending_group_name
  end

  test "should require amount to be greater than 0" do
    spending_zero = Spending.new(
      envelope: @envelope_one,
      amount: 0.0,
      spent_on: Date.today
    )
    assert_not spending_zero.valid?
    assert_includes spending_zero.errors[:amount], "must be greater than 0"

    spending_negative = Spending.new(
      envelope: @envelope_one,
      amount: -10.00,
      spent_on: Date.today
    )
    assert_not spending_negative.valid?
    assert_includes spending_negative.errors[:amount], "must be greater than 0"
  end

  test "should require spent_on" do
    spending = Spending.new(
      envelope: @envelope_one,
      amount: 1200.00
    )
    assert_not spending.valid?
    assert_includes spending.errors[:spent_on], "can't be blank"
  end

  test "should allow notes to be blank" do
    spending = Spending.new(
      envelope: @envelope_one,
      amount: 1200.00,
      spent_on: Date.today,
      notes: nil
    )
    assert spending.valid?
  end

  test "should destroy when envelope is destroyed" do
    envelope_template = EnvelopeTemplate.create!(
      user: users(:one),
      name: "Test Envelope Template",
      group_type: :variable
    )
    envelope = Envelope.create!(
      monthly_budget: monthly_budgets(:one),
      envelope_template: envelope_template,
    )
    spending = Spending.create!(
      envelope: envelope,
      amount: 100.00,
      spent_on: Date.today
    )
    
    assert_difference("Spending.count", -1) do
      envelope.destroy
    end
  end

  test "recent scope should return records ordered by spent_on desc and created_at desc" do
    envelope = envelopes(:two)
    s1 = Spending.create!(envelope: envelope, amount: 10, spent_on: Date.today - 2.days, created_at: 2.days.ago)
    s2 = Spending.create!(envelope: envelope, amount: 20, spent_on: Date.today - 1.day, created_at: 1.day.ago)
    s3 = Spending.create!(envelope: envelope, amount: 30, spent_on: Date.today - 1.day, created_at: 3.days.ago)

    # Scope to just the records we created to avoid fixture interference
    recent_spendings = Spending.where(id: [s1.id, s2.id, s3.id]).recent.to_a
    
    assert_equal s2, recent_spendings[0]
    assert_equal s3, recent_spendings[1]
    assert_equal s1, recent_spendings[2]
  end

  test "for_date scope should return records for specific date" do
    date = Date.parse("2025-12-01")
    spendings_on_date = Spending.for_date(date)
    assert_includes spendings_on_date, spendings(:four)
    spendings_on_date.each do |spending|
      assert_equal date, spending.spent_on
    end
  end

  test "for_date_range scope should return records within date range" do
    start_date = Date.parse("2025-12-01")
    end_date = Date.parse("2025-12-15")
    spendings_in_range = Spending.for_date_range(start_date, end_date)
    assert_includes spendings_in_range, spendings(:one)
    assert_includes spendings_in_range, spendings(:four)
    spendings_in_range.each do |spending|
      assert spending.spent_on >= start_date && spending.spent_on <= end_date
    end
  end

  test "for_envelope scope should return records for specific envelope" do
    envelope_spendings = Spending.for_envelope(@envelope_one)
    assert_includes envelope_spendings, @spending_one
    assert_includes envelope_spendings, @spending_two
    envelope_spendings.each do |spending|
      assert_equal @envelope_one, spending.envelope
    end
  end

  test "formatted_amount should return formatted currency string" do
    spending = Spending.new(amount: 123.456)
    assert_equal "$123.46", spending.formatted_amount
  end

  test "today? should return true if spent_on is today" do
    today_spending = Spending.new(
      envelope: @envelope_one,
      amount: 100.00,
      spent_on: Date.today
    )
    assert today_spending.today?
    
    unless 1.day.ago.to_date == Date.today
      yesterday_spending = Spending.new(
        envelope: @envelope_one,
        amount: 100.00,
        spent_on: 1.day.ago.to_date
      )
      assert_not yesterday_spending.today?
    end
  end

  test "this_week? should return true if spent_on is this week" do
    this_week_spending = Spending.new(
      envelope: @envelope_one,
      amount: 100.00,
      spent_on: Date.today
    )
    assert this_week_spending.this_week?
    
    last_week_spending = Spending.new(
      envelope: @envelope_one,
      amount: 100.00,
      spent_on: 2.weeks.ago.to_date
    )
    assert_not last_week_spending.this_week?
  end

  test "this_month? should return true if spent_on is this month" do
    this_month_spending = Spending.new(
      envelope: @envelope_one,
      amount: 100.00,
      spent_on: Date.today
    )
    assert this_month_spending.this_month?
    
    last_month_spending = Spending.new(
      envelope: @envelope_one,
      amount: 100.00,
      spent_on: 2.months.ago.to_date
    )
    assert_not last_month_spending.this_month?
  end

  test "should access monthly_budget through envelope" do
    assert_equal @envelope_one.monthly_budget, @spending_one.monthly_budget
  end

  test "should access user through monthly_budget" do
    assert_equal @envelope_one.user, @spending_one.user
  end
end

