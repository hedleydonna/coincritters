require "test_helper"

class BillPaymentTest < ActiveSupport::TestCase
  setup do
    @envelope_two = envelopes(:two)
    @envelope_three = envelopes(:three)
    @bill_payment_one = bill_payments(:one)
    @bill_payment_two = bill_payments(:two)
  end

  test "should be valid with valid attributes" do
    bill_payment = BillPayment.new(
      envelope: @envelope_two,
      actual_paid_amount: 1200.00,
      paid_on: Date.today
    )
    assert bill_payment.valid?
  end

  test "should require an envelope" do
    bill_payment = BillPayment.new(
      actual_paid_amount: 1200.00,
      paid_on: Date.today
    )
    assert_not bill_payment.valid?
    assert_includes bill_payment.errors[:envelope], "must exist"
  end

  test "spending_group_name should return envelope's spending_group_name" do
    bill_payment = BillPayment.new(
      envelope: @envelope_two,
      actual_paid_amount: 1200.00,
      paid_on: Date.today
    )
    assert_equal @envelope_two.spending_group_name, bill_payment.spending_group_name
  end

  test "should require actual_paid_amount" do
    bill_payment = BillPayment.new(
      envelope: @envelope_two,
      paid_on: Date.today
    )
    assert_not bill_payment.valid?
    # Rails validates presence and numericality separately
    assert bill_payment.errors[:actual_paid_amount].any?
  end

  test "should require actual_paid_amount to be greater than 0" do
    bill_payment_zero = BillPayment.new(
      envelope: @envelope_two,
      actual_paid_amount: 0.0,
      paid_on: Date.today
    )
    assert_not bill_payment_zero.valid?
    assert_includes bill_payment_zero.errors[:actual_paid_amount], "must be greater than 0"

    bill_payment_negative = BillPayment.new(
      envelope: @envelope_two,
      actual_paid_amount: -10.00,
      paid_on: Date.today
    )
    assert_not bill_payment_negative.valid?
    assert_includes bill_payment_negative.errors[:actual_paid_amount], "must be greater than 0"
  end

  test "should require paid_on" do
    bill_payment = BillPayment.new(
      envelope: @envelope_two,
      actual_paid_amount: 1200.00
    )
    assert_not bill_payment.valid?
    assert_includes bill_payment.errors[:paid_on], "can't be blank"
  end

  test "should allow notes to be blank" do
    bill_payment = BillPayment.new(
      envelope: @envelope_two,
      actual_paid_amount: 1200.00,
      paid_on: Date.today,
      notes: nil
    )
    assert bill_payment.valid?
  end

  test "should destroy when envelope is destroyed" do
    envelope = Envelope.create!(
      monthly_budget: monthly_budgets(:one),
      spending_group_name: "Test Envelope",
      group_type: :fixed
    )
    bill_payment = BillPayment.create!(
      envelope: envelope,
      actual_paid_amount: 100.00,
      paid_on: Date.today
    )
    
    assert_difference("BillPayment.count", -1) do
      envelope.destroy
    end
  end

  test "recent scope should return records ordered by paid_on desc and created_at desc" do
    envelope = envelopes(:two)
    bp1 = BillPayment.create!(envelope: envelope, actual_paid_amount: 10, paid_on: Date.today - 2.days, created_at: 2.days.ago)
    bp2 = BillPayment.create!(envelope: envelope, actual_paid_amount: 20, paid_on: Date.today - 1.day, created_at: 1.day.ago)
    bp3 = BillPayment.create!(envelope: envelope, actual_paid_amount: 30, paid_on: Date.today - 1.day, created_at: 3.days.ago)

    recent_payments = BillPayment.recent.to_a
    
    assert_equal bp2, recent_payments[0]
    assert_equal bp3, recent_payments[1]
    assert_equal bp1, recent_payments[2]
  end

  test "for_date scope should return records for specific date" do
    date = Date.parse("2025-12-01")
    payments_on_date = BillPayment.for_date(date)
    assert_includes payments_on_date, @bill_payment_one
    payments_on_date.each do |payment|
      assert_equal date, payment.paid_on
    end
  end

  test "for_date_range scope should return records within date range" do
    start_date = Date.parse("2025-12-01")
    end_date = Date.parse("2025-12-05")
    payments_in_range = BillPayment.for_date_range(start_date, end_date)
    assert_includes payments_in_range, @bill_payment_one
    assert_includes payments_in_range, bill_payments(:three)
    payments_in_range.each do |payment|
      assert payment.paid_on >= start_date && payment.paid_on <= end_date
    end
  end

  test "for_envelope scope should return records for specific envelope" do
    envelope_payments = BillPayment.for_envelope(@envelope_two)
    assert_includes envelope_payments, @bill_payment_one
    assert_includes envelope_payments, @bill_payment_two
    envelope_payments.each do |payment|
      assert_equal @envelope_two, payment.envelope
    end
  end

  test "formatted_amount should return formatted currency string" do
    bill_payment = BillPayment.new(actual_paid_amount: 123.456)
    assert_equal "$123.46", bill_payment.formatted_amount
  end

  test "today? should return true if paid_on is today" do
    today_payment = BillPayment.new(
      envelope: @envelope_two,
      actual_paid_amount: 100.00,
      paid_on: Date.today
    )
    assert today_payment.today?
    
    unless 1.day.ago.to_date == Date.today
      yesterday_payment = BillPayment.new(
        envelope: @envelope_two,
        actual_paid_amount: 100.00,
        paid_on: 1.day.ago.to_date
      )
      assert_not yesterday_payment.today?
    end
  end

  test "this_week? should return true if paid_on is this week" do
    this_week_payment = BillPayment.new(
      envelope: @envelope_two,
      actual_paid_amount: 100.00,
      paid_on: Date.today
    )
    assert this_week_payment.this_week?
    
    last_week_payment = BillPayment.new(
      envelope: @envelope_two,
      actual_paid_amount: 100.00,
      paid_on: 2.weeks.ago.to_date
    )
    assert_not last_week_payment.this_week?
  end

  test "this_month? should return true if paid_on is this month" do
    this_month_payment = BillPayment.new(
      envelope: @envelope_two,
      actual_paid_amount: 100.00,
      paid_on: Date.today
    )
    assert this_month_payment.this_month?
    
    last_month_payment = BillPayment.new(
      envelope: @envelope_two,
      actual_paid_amount: 100.00,
      paid_on: 2.months.ago.to_date
    )
    assert_not last_month_payment.this_month?
  end

  test "should access monthly_budget through envelope" do
    assert_equal @envelope_two.monthly_budget, @bill_payment_one.monthly_budget
  end

  test "should access user through monthly_budget" do
    assert_equal @envelope_two.user, @bill_payment_one.user
  end
end

