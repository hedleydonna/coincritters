require "test_helper"

class EnvelopeTemplateTest < ActiveSupport::TestCase
  setup do
    @user_one = users(:one)
    @user_two = users(:two)
    @envelope_template_one = envelope_templates(:one)  # Groceries (variable)
    @envelope_template_two = envelope_templates(:two)  # Rent (fixed)
    @envelope_template_three = envelope_templates(:three)  # Emergency Fund (fixed, savings)
  end

  test "should be valid with valid attributes" do
    envelope_template = EnvelopeTemplate.new(
      user: @user_one,
      name: "Utilities",
      group_type: :fixed,
      is_savings: false,
      default_amount: 150.00,
      auto_create: true
    )
    assert envelope_template.valid?
  end

  test "should require a user" do
    envelope_template = EnvelopeTemplate.new(
      name: "Test Template",
      group_type: :variable
    )
    assert_not envelope_template.valid?
    assert_includes envelope_template.errors[:user], "must exist"
  end

  test "should require name" do
    envelope_template = EnvelopeTemplate.new(
      user: @user_one,
      group_type: :variable
    )
    assert_not envelope_template.valid?
    assert_includes envelope_template.errors[:name], "can't be blank"
  end

  test "should enforce unique name per user" do
    duplicate_template = EnvelopeTemplate.new(
      user: @user_one,
      name: @envelope_template_one.name,
      group_type: :variable
    )
    assert_not duplicate_template.valid?
    assert_includes duplicate_template.errors[:name], "has already been taken"
  end

  test "different users can have templates with same name" do
    # Both user_one and user_two can have "Groceries"
    assert_equal "Groceries", envelope_templates(:one).name
    assert_equal "Groceries", envelope_templates(:four).name
    assert_equal users(:one), envelope_templates(:one).user
    assert_equal users(:two), envelope_templates(:four).user
    
    assert envelope_templates(:one).valid?
    assert envelope_templates(:four).valid?
  end

  test "should validate group_type inclusion" do
    envelope_template = EnvelopeTemplate.new(
      user: @user_one,
      name: "Test"
    )
    # Rails enum raises ArgumentError for invalid values before validation
    assert_raises(ArgumentError) do
      envelope_template.group_type = 999
    end
    # Valid values work fine
    envelope_template.group_type = :fixed
    assert envelope_template.valid?
  end

  test "should accept valid group_type values" do
    fixed_template = EnvelopeTemplate.new(
      user: @user_one,
      name: "Fixed Test",
      group_type: :fixed
    )
    assert fixed_template.valid?

    variable_template = EnvelopeTemplate.new(
      user: @user_one,
      name: "Variable Test",
      group_type: :variable
    )
    assert variable_template.valid?
  end

  test "should default group_type to variable" do
    envelope_template = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Default Test"
    )
    assert_equal "variable", envelope_template.group_type
    assert envelope_template.variable?
  end

  test "should default is_savings to false" do
    envelope_template = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Default Savings Test"
    )
    assert_not envelope_template.is_savings?
  end

  test "should default auto_create to true" do
    envelope_template = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Default Auto Create Test"
    )
    assert envelope_template.auto_create?
  end

  test "should require default_amount to be greater than or equal to 0" do
    envelope_template = EnvelopeTemplate.new(
      user: @user_one,
      name: "Test",
      default_amount: -100.00
    )
    assert_not envelope_template.valid?
    assert_includes envelope_template.errors[:default_amount], "must be greater than or equal to 0"
  end

  test "should allow default_amount to be nil" do
    envelope_template = EnvelopeTemplate.new(
      user: @user_one,
      name: "Test With Nil Amount",
      default_amount: nil
    )
    assert envelope_template.valid?
  end

  test "should destroy when user is destroyed" do
    user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    envelope_template = EnvelopeTemplate.create!(
      user: user,
      name: "Test Template"
    )
    
    assert_difference("EnvelopeTemplate.count", -1) do
      user.destroy
    end
  end

  test "should destroy dependent envelopes when destroyed" do
    envelope_template = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Test Template For Deletion"
    )
    envelope = Envelope.create!(
      monthly_budget: monthly_budgets(:one),
      envelope_template: envelope_template
    )
    
    assert_difference("Envelope.count", -1) do
      envelope_template.destroy
    end
  end

  test "fixed scope should return only fixed templates" do
    fixed_templates = EnvelopeTemplate.fixed
    assert_includes fixed_templates, @envelope_template_two
    assert_not_includes fixed_templates, @envelope_template_one
  end

  test "variable scope should return only variable templates" do
    variable_templates = EnvelopeTemplate.variable
    assert_includes variable_templates, @envelope_template_one
    assert_not_includes variable_templates, @envelope_template_two
  end

  test "savings scope should return only savings templates" do
    savings_templates = EnvelopeTemplate.savings
    assert_includes savings_templates, @envelope_template_three
    assert_not_includes savings_templates, @envelope_template_one
  end

  test "non_savings scope should return only non-savings templates" do
    non_savings_templates = EnvelopeTemplate.non_savings
    assert_includes non_savings_templates, @envelope_template_one
    assert_not_includes non_savings_templates, @envelope_template_three
  end

  test "auto_create scope should return only auto-create templates" do
    auto_create_templates = EnvelopeTemplate.auto_create
    assert_includes auto_create_templates, @envelope_template_one
  end

  test "display_name should include (Savings) for savings templates" do
    assert_equal "Emergency Fund (Savings)", @envelope_template_three.display_name
    assert_equal "Groceries", @envelope_template_one.display_name
  end

  test "group_type_text should return correct text" do
    assert_equal "Fixed bill", @envelope_template_two.group_type_text
    assert_equal "Variable spending", @envelope_template_one.group_type_text
  end

  test "should default is_active to true" do
    envelope_template = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Default Active Test"
    )
    assert envelope_template.is_active?
    assert envelope_template.active?
  end

  test "active scope should return only active templates" do
    active_template = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Active Template",
      is_active: true
    )
    inactive_template = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Inactive Template",
      is_active: false
    )
    
    active_templates = EnvelopeTemplate.active
    assert_includes active_templates, active_template
    assert_not_includes active_templates, inactive_template
  end

  test "inactive scope should return only inactive templates" do
    active_template = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Active Template 2",
      is_active: true
    )
    inactive_template = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Inactive Template 2",
      is_active: false
    )
    
    inactive_templates = EnvelopeTemplate.inactive
    assert_includes inactive_templates, inactive_template
    assert_not_includes inactive_templates, active_template
  end

  test "deactivate! should set is_active to false" do
    template = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Template To Deactivate"
    )
    assert template.is_active?
    
    template.deactivate!
    template.reload
    assert_not template.is_active?
    assert_not template.active?
  end

  test "activate! should set is_active to true" do
    template = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Template To Activate",
      is_active: false
    )
    assert_not template.is_active?
    
    template.activate!
    template.reload
    assert template.is_active?
    assert template.active?
  end

  test "should allow same name for active and inactive templates for same user" do
    active_template = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Shared Name",
      is_active: true
    )
    
    # Deactivate the first one
    active_template.deactivate!
    
    # Should be able to create a new active template with the same name
    new_active_template = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Shared Name",
      is_active: true
    )
    assert new_active_template.valid?
    assert new_active_template.persisted?
  end

  test "should not allow duplicate active templates with same name for same user" do
    EnvelopeTemplate.create!(
      user: @user_one,
      name: "Unique Name",
      is_active: true
    )
    
    duplicate = EnvelopeTemplate.new(
      user: @user_one,
      name: "Unique Name",
      is_active: true
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end
end

