require "test_helper"

class EnvelopeTest < ActiveSupport::TestCase
  setup do
    @monthly_budget_one = monthly_budgets(:one)
    @monthly_budget_two = monthly_budgets(:two)
    @envelope_one = envelopes(:one)
    @envelope_two = envelopes(:two)
  end

  test "should be valid with valid attributes" do
    spending_category = SpendingCategory.create!(
      user: @monthly_budget_one.user,
      name: "Utilities",
      group_type: :fixed
    )
    envelope = Envelope.new(
      monthly_budget: @monthly_budget_one,
      spending_category: spending_category,
      allotted_amount: 150.00
    )
    assert envelope.valid?
  end

  test "should require a monthly_budget" do
    spending_category = spending_categories(:one)
    envelope = Envelope.new(
      spending_category: spending_category
    )
    assert_not envelope.valid?
    assert_includes envelope.errors[:monthly_budget], "must exist"
  end

  test "should require a spending_category" do
    envelope = Envelope.new(
      monthly_budget: @monthly_budget_one
    )
    assert_not envelope.valid?
    assert_includes envelope.errors[:spending_category], "must exist"
  end

  test "should enforce unique spending_category per monthly_budget" do
    spending_category = spending_categories(:one)
    duplicate_envelope = Envelope.new(
      monthly_budget: @monthly_budget_one,
      spending_category: spending_category
    )
    assert_not duplicate_envelope.valid?
    assert_includes duplicate_envelope.errors[:spending_category], "has already been taken"
  end

  test "different monthly_budgets can have envelopes with same spending_category" do
    # envelope_one uses spending_category one in monthly_budget_one
    # Different budgets can use the same spending category
    assert_equal spending_categories(:one), envelopes(:one).spending_category
    assert_equal monthly_budgets(:one), envelopes(:one).monthly_budget
    
    # Both envelopes are valid even though they share the same spending category (in different budgets)
    assert envelopes(:one).valid?
    assert envelopes(:four).valid?
  end

  test "should get group_type from spending_category" do
    fixed_category = spending_categories(:two)  # Rent (fixed)
    variable_category = spending_categories(:one)  # Groceries (variable)
    
    # Need unique spending categories for different budgets to avoid unique constraint
    fixed_category_two = SpendingCategory.create!(
      user: @monthly_budget_two.user,
      name: "Fixed Test Category",
      group_type: :fixed
    )
    variable_category_two = SpendingCategory.create!(
      user: @monthly_budget_two.user,
      name: "Variable Test Category",
      group_type: :variable
    )
    
    fixed_envelope = Envelope.new(
      monthly_budget: @monthly_budget_two,
      spending_category: fixed_category_two
    )
    assert_equal "fixed", fixed_envelope.group_type
    assert fixed_envelope.fixed?

    variable_envelope = Envelope.new(
      monthly_budget: @monthly_budget_two,
      spending_category: variable_category_two
    )
    assert_equal "variable", variable_envelope.group_type
    assert variable_envelope.variable?
  end

  test "should get is_savings from spending_category" do
    savings_category = spending_categories(:three)  # Emergency Fund (savings)
    non_savings_category = spending_categories(:one)  # Groceries (non-savings)
    
    # Using existing envelope from fixtures
    assert envelopes(:three).is_savings?
    assert_not @envelope_one.is_savings?
  end

  test "should require allotted_amount to be greater than or equal to 0" do
    spending_category = SpendingCategory.create!(
      user: @monthly_budget_one.user,
      name: "Test Category",
      group_type: :variable
    )
    envelope = Envelope.new(
      monthly_budget: @monthly_budget_one,
      spending_category: spending_category,
      allotted_amount: -100.00
    )
    assert_not envelope.valid?
    assert_includes envelope.errors[:allotted_amount], "must be greater than or equal to 0"
  end

  test "should have default allotted_amount of 0.0" do
    # Create a unique spending category for this test to avoid unique constraint violation
    spending_category = SpendingCategory.create!(
      user: @monthly_budget_one.user,
      name: "Default Amount Test Category",
      group_type: :variable
    )
    envelope = Envelope.create!(
      monthly_budget: @monthly_budget_one,
      spending_category: spending_category
    )
    assert_equal 0.0, envelope.allotted_amount.to_f
  end

  test "spent_amount should calculate from spendings" do
    # envelope_one has spendings totaling 75.50 + 45.25 + 120.00 = 240.75
    assert_equal 240.75, @envelope_one.spent_amount.to_f
    
    # envelope_two has spendings totaling 1200.00 + 1200.00 = 2400.00
    assert_equal 2400.00, @envelope_two.spent_amount.to_f
    
    # envelope with no spendings should be 0
    assert_equal 0.0, envelopes(:three).spent_amount.to_f
  end

  test "should destroy when monthly_budget is destroyed" do
    budget = MonthlyBudget.create!(
      user: users(:one),
      month_year: "2026-03"
    )
    spending_category = SpendingCategory.create!(
      user: users(:one),
      name: "Test Category",
      group_type: :variable
    )
    envelope = Envelope.create!(
      monthly_budget: budget,
      spending_category: spending_category
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

  test "should destroy when spending_category is destroyed" do
    spending_category = SpendingCategory.create!(
      user: users(:one),
      name: "Test Category For Deletion"
    )
    envelope = Envelope.create!(
      monthly_budget: @monthly_budget_one,
      spending_category: spending_category
    )
    
    assert_difference("Envelope.count", -1) do
      spending_category.destroy
    end
  end

  test "remaining should calculate allotted minus spent" do
    # envelope_one: allotted 500.00, spent 240.75 (from spendings), remaining 259.25
    assert_equal 259.25, @envelope_one.remaining.to_f
    # envelope_two: allotted 1200.00, spent 2400.00 (from spendings), remaining -1200.00
    assert_equal -1200.00, @envelope_two.remaining.to_f
  end

  test "available should return remaining or 0, whichever is higher" do
    # envelope_one: remaining 259.25
    assert_equal 259.25, @envelope_one.available.to_f
    
    # Create an envelope that's over budget
    spending_category = SpendingCategory.create!(
      user: @monthly_budget_one.user,
      name: "Over Budget Test Category",
      group_type: :variable
    )
    over_budget = Envelope.create!(
      monthly_budget: @monthly_budget_one,
      spending_category: spending_category,
      allotted_amount: 100.00
    )
    Spending.create!(
      envelope: over_budget,
      amount: 150.00,
      spent_on: Date.today
    )
    assert_equal 0.0, over_budget.available.to_f
  end

  test "over_budget? should return true when spent exceeds allotted" do
    # envelope_two is over budget (spent 2400 > allotted 1200)
    assert @envelope_two.over_budget?
    # envelope_one is not over budget (spent 240.75 < allotted 500)
    assert_not @envelope_one.over_budget?
  end

  test "spent_percentage should calculate percentage correctly" do
    # envelope_one: 240.75 / 500.00 = 48.15%
    assert_equal 48.2, @envelope_one.spent_percentage
    # envelope_two: 2400.00 / 1200.00 = 200%, capped at 100%
    assert_equal 100.0, @envelope_two.spent_percentage
    
    spending_category = SpendingCategory.create!(
      user: @monthly_budget_one.user,
      name: "Empty Test Category",
      group_type: :variable
    )
    empty_envelope = Envelope.create!(
      monthly_budget: @monthly_budget_one,
      spending_category: spending_category,
      allotted_amount: 0.00
    )
    assert_equal 0, empty_envelope.spent_percentage
  end

  test "spent_percentage should cap at 100" do
    # envelope_two already exceeds 100% so it should be capped
    assert_equal 100.0, @envelope_two.spent_percentage
  end
end

