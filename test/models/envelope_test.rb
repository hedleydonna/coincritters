require "test_helper"

class EnvelopeTest < ActiveSupport::TestCase
  setup do
    @monthly_budget_one = monthly_budgets(:one)
    @monthly_budget_two = monthly_budgets(:two)
    @envelope_one = envelopes(:one)
    @envelope_two = envelopes(:two)
  end

  test "should be valid with valid attributes" do
    envelope_template = EnvelopeTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Utilities",
      group_type: :fixed
    )
    envelope = Envelope.new(
      monthly_budget: @monthly_budget_one,
      envelope_template: envelope_template,
      allotted_amount: 150.00
    )
    assert envelope.valid?
  end

  test "should require a monthly_budget" do
    envelope_template = envelope_templates(:one)
    envelope = Envelope.new(
      envelope_template: envelope_template
    )
    assert_not envelope.valid?
    assert_includes envelope.errors[:monthly_budget], "must exist"
  end

  test "should require an envelope_template" do
    envelope = Envelope.new(
      monthly_budget: @monthly_budget_one
    )
    assert_not envelope.valid?
    assert_includes envelope.errors[:envelope_template], "must exist"
  end

  test "should enforce unique envelope_template per monthly_budget" do
    envelope_template = envelope_templates(:one)
    duplicate_envelope = Envelope.new(
      monthly_budget: @monthly_budget_one,
      envelope_template: envelope_template
    )
    assert_not duplicate_envelope.valid?
    assert_includes duplicate_envelope.errors[:envelope_template_id], "already has an envelope for this template in this budget"
  end

  test "different monthly_budgets can have envelopes with same envelope_template" do
    # envelope_one uses envelope_template one in monthly_budget_one
    # Different budgets can use the same envelope template
    assert_equal envelope_templates(:one), envelopes(:one).envelope_template
    assert_equal monthly_budgets(:one), envelopes(:one).monthly_budget
    
    # Both envelopes are valid even though they share the same envelope template (in different budgets)
    assert envelopes(:one).valid?
    assert envelopes(:four).valid?
  end

  test "should get group_type from envelope_template" do
    fixed_template = envelope_templates(:two)  # Rent (fixed)
    variable_template = envelope_templates(:one)  # Groceries (variable)
    
    # Need unique envelope templates for different budgets to avoid unique constraint
    fixed_template_two = EnvelopeTemplate.create!(
      user: @monthly_budget_two.user,
      name: "Fixed Test Template",
      group_type: :fixed
    )
    variable_template_two = EnvelopeTemplate.create!(
      user: @monthly_budget_two.user,
      name: "Variable Test Template",
      group_type: :variable
    )
    
    fixed_envelope = Envelope.new(
      monthly_budget: @monthly_budget_two,
      envelope_template: fixed_template_two
    )
    assert_equal "fixed", fixed_envelope.group_type
    assert fixed_envelope.fixed?

    variable_envelope = Envelope.new(
      monthly_budget: @monthly_budget_two,
      envelope_template: variable_template_two
    )
    assert_equal "variable", variable_envelope.group_type
    assert variable_envelope.variable?
  end

  test "should get is_savings from envelope_template" do
    savings_template = envelope_templates(:three)  # Emergency Fund (savings)
    non_savings_template = envelope_templates(:one)  # Groceries (non-savings)
    
    # Using existing envelope from fixtures
    assert envelopes(:three).is_savings?
    assert_not @envelope_one.is_savings?
  end

  test "savings? should return true for savings envelopes" do
    assert envelopes(:three).savings?
    assert_not @envelope_one.savings?
  end

  test "savings? and is_savings? should return same value" do
    savings_envelope = envelopes(:three)
    assert_equal savings_envelope.savings?, savings_envelope.is_savings?
    
    non_savings_envelope = @envelope_one
    assert_equal non_savings_envelope.savings?, non_savings_envelope.is_savings?
  end

  test "should require allotted_amount to be greater than or equal to 0" do
    envelope_template = EnvelopeTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Test Template",
      group_type: :variable
    )
    envelope = Envelope.new(
      monthly_budget: @monthly_budget_one,
      envelope_template: envelope_template,
      allotted_amount: -100.00
    )
    assert_not envelope.valid?
    assert_includes envelope.errors[:allotted_amount], "must be greater than or equal to 0"
  end

  test "should auto-fill allotted_amount from template default_amount when creating" do
    # Create a unique envelope template with a default amount
    envelope_template = EnvelopeTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Auto Fill Test Template",
      group_type: :variable,
      default_amount: 250.00
    )
    envelope = Envelope.create!(
      monthly_budget: @monthly_budget_one,
      envelope_template: envelope_template
    )
    assert_equal 250.00, envelope.allotted_amount.to_f
  end

  test "should use 0.0 as default allotted_amount if template default_amount is nil" do
    # Create a unique envelope template without a default amount
    envelope_template = EnvelopeTemplate.create!(
      user: @monthly_budget_one.user,
      name: "No Default Amount Test Template",
      group_type: :variable,
      default_amount: nil
    )
    envelope = Envelope.create!(
      monthly_budget: @monthly_budget_one,
      envelope_template: envelope_template
    )
    assert_equal 0.0, envelope.allotted_amount.to_f
  end

  test "should not override explicitly set allotted_amount with default" do
    envelope_template = EnvelopeTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Explicit Amount Test Template",
      group_type: :variable,
      default_amount: 100.00
    )
    envelope = Envelope.create!(
      monthly_budget: @monthly_budget_one,
      envelope_template: envelope_template,
      allotted_amount: 500.00
    )
    assert_equal 500.00, envelope.allotted_amount.to_f
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
    envelope_template = EnvelopeTemplate.create!(
      user: users(:one),
      name: "Test Template",
      group_type: :variable
    )
    envelope = Envelope.create!(
      monthly_budget: budget,
      envelope_template: envelope_template
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

  test "over_budget scope should return only envelopes where spent exceeds allotted" do
    # envelope_two is over budget (spent 2400 > allotted 1200)
    over_budget_envelopes = Envelope.over_budget
    assert_includes over_budget_envelopes, @envelope_two
    assert_not_includes over_budget_envelopes, @envelope_one
  end

  test "fixed? should return true for fixed envelopes" do
    assert @envelope_two.fixed?
    assert_not @envelope_one.fixed?
  end

  test "variable? should return true for variable envelopes" do
    assert @envelope_one.variable?
    assert_not @envelope_two.variable?
  end

  test "should destroy when envelope_template is destroyed" do
    envelope_template = EnvelopeTemplate.create!(
      user: users(:one),
      name: "Test Template For Deletion"
    )
    envelope = Envelope.create!(
      monthly_budget: @monthly_budget_one,
      envelope_template: envelope_template
    )
    
    assert_difference("Envelope.count", -1) do
      envelope_template.destroy
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
    envelope_template = EnvelopeTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Over Budget Test Template",
      group_type: :variable
    )
    over_budget = Envelope.create!(
      monthly_budget: @monthly_budget_one,
      envelope_template: envelope_template,
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
    
    envelope_template = EnvelopeTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Empty Test Template",
      group_type: :variable
    )
    empty_envelope = Envelope.create!(
      monthly_budget: @monthly_budget_one,
      envelope_template: envelope_template,
      allotted_amount: 0.00
    )
    assert_equal 0, empty_envelope.spent_percentage
    
    # Test with negative allotted_amount (edge case - shouldn't happen but safer)
    negative_envelope = Envelope.new(
      monthly_budget: @monthly_budget_one,
      envelope_template: envelope_template,
      allotted_amount: -100.00
    )
    assert_equal 0, negative_envelope.spent_percentage
  end

  test "spent_percentage should cap at 100" do
    # envelope_two already exceeds 100% so it should be capped
    assert_equal 100.0, @envelope_two.spent_percentage
  end

  test "paid? should return true for fixed envelopes when spent >= allotted" do
    # Create a fixed template
    fixed_template = EnvelopeTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Fixed Bill Test",
      group_type: :fixed
    )
    
    # Create envelope with allotted amount
    fixed_envelope = Envelope.create!(
      monthly_budget: @monthly_budget_one,
      envelope_template: fixed_template,
      allotted_amount: 1000.00
    )
    
    # Not paid yet
    assert_not fixed_envelope.paid?
    
    # Add spending that equals allotted amount
    Spending.create!(
      envelope: fixed_envelope,
      amount: 1000.00,
      spent_on: Date.today
    )
    assert fixed_envelope.paid?
    
    # Add more spending (over paid)
    Spending.create!(
      envelope: fixed_envelope,
      amount: 100.00,
      spent_on: Date.today
    )
    assert fixed_envelope.paid?
  end

  test "paid? should return false for variable envelopes even when spent >= allotted" do
    # Create a variable template
    variable_template = EnvelopeTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Variable Test",
      group_type: :variable
    )
    
    variable_envelope = Envelope.create!(
      monthly_budget: @monthly_budget_one,
      envelope_template: variable_template,
      allotted_amount: 500.00
    )
    
    # Add spending that exceeds allotted
    Spending.create!(
      envelope: variable_envelope,
      amount: 600.00,
      spent_on: Date.today
    )
    
    # Variable envelopes are never "paid" - only fixed bills can be paid
    assert_not variable_envelope.paid?
  end

  test "to_s should return friendly string with name and budget" do
    envelope = @envelope_one
    to_s_string = envelope.to_s
    assert_match(/#{envelope.name}/, to_s_string)
    assert_match(/#{envelope.monthly_budget.name}/, to_s_string)
  end

  test "name should use envelope_template name by default" do
    envelope = @envelope_one
    assert_equal envelope.envelope_template.name, envelope.name
  end

  test "name should use override when provided" do
    envelope_template = EnvelopeTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Template Name",
      group_type: :variable
    )
    envelope = Envelope.create!(
      monthly_budget: @monthly_budget_one,
      envelope_template: envelope_template,
      name: "Custom Override Name"
    )
    assert_equal "Custom Override Name", envelope.name
    assert envelope.name_overridden?
  end

  test "display_name should use envelope_template or override" do
    envelope = @envelope_one
    assert_equal envelope.envelope_template.display_name, envelope.display_name
  end

  test "display_name should show (Savings) for savings envelopes" do
    savings_envelope = envelopes(:three)
    assert_match(/Savings/, savings_envelope.display_name)
  end

  test "percent_used should return integer percentage" do
    # envelope_one: 240.75 / 500.00 = 48.15%, rounded to 48
    assert_equal 48, @envelope_one.percent_used
    
    # envelope_two: 2400.00 / 1200.00 = 200%, rounded to 200
    assert_equal 200, @envelope_two.percent_used
    
    # Empty envelope
    envelope_template = EnvelopeTemplate.create!(
      user: @monthly_budget_one.user,
      name: "Empty Percent Test",
      group_type: :variable
    )
    empty_envelope = Envelope.create!(
      monthly_budget: @monthly_budget_one,
      envelope_template: envelope_template,
      allotted_amount: 0.00
    )
    assert_equal 0, empty_envelope.percent_used
  end
end

