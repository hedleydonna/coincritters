require "test_helper"

class EnvelopeTest < ActiveSupport::TestCase
  setup do
    @monthly_budget_one = monthly_budgets(:one)
    @monthly_budget_two = monthly_budgets(:two)
    @envelope_one = envelopes(:one)
    @envelope_two = envelopes(:two)
  end

  test "should be valid with valid attributes" do
    envelope = Envelope.new(
      monthly_budget: @monthly_budget_one,
      spending_group_name: "Utilities",
      group_type: 0,
      is_savings: false,
      allotted_amount: 150.00,
      spent_amount: 120.00
    )
    assert envelope.valid?
  end

  test "should require a monthly_budget" do
    envelope = Envelope.new(
      spending_group_name: "Test",
      group_type: 1
    )
    assert_not envelope.valid?
    assert_includes envelope.errors[:monthly_budget], "must exist"
  end

  test "should require spending_group_name" do
    envelope = Envelope.new(
      monthly_budget: @monthly_budget_one,
      group_type: 1
    )
    assert_not envelope.valid?
    assert_includes envelope.errors[:spending_group_name], "can't be blank"
  end

  test "should enforce unique spending_group_name per monthly_budget" do
    duplicate_envelope = Envelope.new(
      monthly_budget: @monthly_budget_one,
      spending_group_name: @envelope_one.spending_group_name,
      group_type: 1
    )
    assert_not duplicate_envelope.valid?
    assert_includes duplicate_envelope.errors[:spending_group_name], "already exists for this budget"
  end

  test "different monthly_budgets can have envelopes with same spending_group_name" do
    # envelope_one is "Groceries" in monthly_budget_one
    # envelope_four is "Groceries" in monthly_budget_two
    # Both can exist because they're in different budgets
    assert_equal "Groceries", envelopes(:one).spending_group_name
    assert_equal "Groceries", envelopes(:four).spending_group_name
    assert_equal monthly_budgets(:one), envelopes(:one).monthly_budget
    assert_equal monthly_budgets(:two), envelopes(:four).monthly_budget
    
    # Both envelopes are valid even though they share the same name
    assert envelopes(:one).valid?
    assert envelopes(:four).valid?
  end

  test "should validate group_type inclusion" do
    envelope = Envelope.new(
      monthly_budget: @monthly_budget_one,
      spending_group_name: "Test"
    )
    # Rails enum raises ArgumentError for invalid values before validation
    assert_raises(ArgumentError, "'999' is not a valid group_type") do
      envelope.group_type = 999
    end
    # Valid values work fine
    envelope.group_type = :fixed
    assert envelope.valid?
  end

  test "should accept valid group_type values" do
    fixed_envelope = Envelope.new(
      monthly_budget: @monthly_budget_one,
      spending_group_name: "Fixed Test",
      group_type: :fixed
    )
    assert fixed_envelope.valid?

    variable_envelope = Envelope.new(
      monthly_budget: @monthly_budget_one,
      spending_group_name: "Variable Test",
      group_type: :variable
    )
    assert variable_envelope.valid?
  end

  test "should default group_type to variable" do
    envelope = Envelope.create!(
      monthly_budget: @monthly_budget_one,
      spending_group_name: "Default Test"
    )
    assert_equal "variable", envelope.group_type
    assert envelope.variable?
  end

  test "should default is_savings to false" do
    envelope = Envelope.create!(
      monthly_budget: @monthly_budget_one,
      spending_group_name: "Default Savings Test"
    )
    assert_not envelope.is_savings?
  end

  test "should require allotted_amount to be greater than or equal to 0" do
    envelope = Envelope.new(
      monthly_budget: @monthly_budget_one,
      spending_group_name: "Test",
      group_type: 1,
      allotted_amount: -100.00
    )
    assert_not envelope.valid?
    assert_includes envelope.errors[:allotted_amount], "must be greater than or equal to 0"
  end

  test "should have default allotted_amount of 0.0" do
    envelope = Envelope.create!(
      monthly_budget: @monthly_budget_one,
      spending_group_name: "Default Amount Test"
    )
    assert_equal 0.0, envelope.allotted_amount.to_f
  end

  test "should require spent_amount to be greater than or equal to 0" do
    envelope = Envelope.new(
      monthly_budget: @monthly_budget_one,
      spending_group_name: "Test",
      group_type: 1,
      spent_amount: -50.00
    )
    assert_not envelope.valid?
    assert_includes envelope.errors[:spent_amount], "must be greater than or equal to 0"
  end

  test "should have default spent_amount of 0.0" do
    envelope = Envelope.create!(
      monthly_budget: @monthly_budget_one,
      spending_group_name: "Default Spent Test"
    )
    assert_equal 0.0, envelope.spent_amount.to_f
  end

  test "should destroy when monthly_budget is destroyed" do
    budget = MonthlyBudget.create!(
      user: users(:one),
      month_year: "2026-03"
    )
    envelope = Envelope.create!(
      monthly_budget: budget,
      spending_group_name: "Test Envelope"
    )
    
    assert_difference("Envelope.count", -1) do
      budget.destroy
    end
  end

  test "fixed scope should return only fixed envelopes" do
    fixed_envelopes = Envelope.fixed
    assert_includes fixed_envelopes, @envelope_two
    assert_not_includes fixed_envelopes, @envelope_one
  end

  test "variable scope should return only variable envelopes" do
    variable_envelopes = Envelope.variable
    assert_includes variable_envelopes, @envelope_one
    assert_not_includes variable_envelopes, @envelope_two
  end

  test "savings scope should return only savings envelopes" do
    savings_envelopes = Envelope.savings
    assert_includes savings_envelopes, envelopes(:three)
    assert_not_includes savings_envelopes, @envelope_one
  end

  test "non_savings scope should return only non-savings envelopes" do
    non_savings_envelopes = Envelope.non_savings
    assert_includes non_savings_envelopes, @envelope_one
    assert_not_includes non_savings_envelopes, envelopes(:three)
  end

  test "fixed? should return true for fixed envelopes" do
    assert @envelope_two.fixed?
    assert_not @envelope_one.fixed?
  end

  test "variable? should return true for variable envelopes" do
    assert @envelope_one.variable?
    assert_not @envelope_two.variable?
  end

  test "remaining should calculate allotted minus spent" do
    assert_equal 179.50, @envelope_one.remaining.to_f
    assert_equal 0.0, @envelope_two.remaining.to_f
  end

  test "available should return remaining or 0, whichever is higher" do
    assert_equal 179.50, @envelope_one.available.to_f
    
    over_budget = Envelope.new(
      monthly_budget: @monthly_budget_one,
      spending_group_name: "Over Budget Test",
      allotted_amount: 100.00,
      spent_amount: 150.00
    )
    assert_equal 0.0, over_budget.available.to_f
  end

  test "over_budget? should return true when spent exceeds allotted" do
    over_budget_envelope = Envelope.new(
      monthly_budget: @monthly_budget_one,
      spending_group_name: "Over Budget",
      allotted_amount: 100.00,
      spent_amount: 150.00
    )
    assert over_budget_envelope.over_budget?
    assert_not @envelope_one.over_budget?
  end

  test "spent_percentage should calculate percentage correctly" do
    assert_equal 64.1, @envelope_one.spent_percentage
    assert_equal 100.0, @envelope_two.spent_percentage
    
    empty_envelope = Envelope.new(
      monthly_budget: @monthly_budget_one,
      spending_group_name: "Empty",
      allotted_amount: 0.00,
      spent_amount: 0.00
    )
    assert_equal 0, empty_envelope.spent_percentage
  end

  test "spent_percentage should cap at 100" do
    over_budget_envelope = Envelope.new(
      monthly_budget: @monthly_budget_one,
      spending_group_name: "Over Budget",
      allotted_amount: 100.00,
      spent_amount: 200.00
    )
    assert_equal 100.0, over_budget_envelope.spent_percentage
  end
end

