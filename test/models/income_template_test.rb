require "test_helper"

class IncomeTemplateTest < ActiveSupport::TestCase
  # Test fixtures
  test "should have valid fixtures" do
    assert income_templates(:one).valid?
    assert income_templates(:two).valid?
    assert income_templates(:three).valid?
  end

  # Test associations
  test "should belong to user" do
    income_template = income_templates(:one)
    assert_not_nil income_template.user
    assert_equal users(:one), income_template.user
  end

  test "should be destroyed when user is destroyed" do
    user = users(:one)
    income_template = user.income_templates.create!(name: "Test IncomeTemplate", frequency: "monthly", estimated_amount: 100)
    income_template_id = income_template.id
    
    user.destroy
    assert_nil IncomeTemplate.find_by(id: income_template_id)
  end

  # Test name validation
  test "name should be present" do
    income_template = IncomeTemplate.new(user: users(:one), frequency: "monthly", estimated_amount: 100)
    assert_not income_template.valid?
    assert_includes income_template.errors[:name], "can't be blank"
  end

  test "should save with valid name" do
    income_template = IncomeTemplate.new(user: users(:one), name: "New IncomeTemplate", frequency: "monthly", estimated_amount: 100)
    assert income_template.save
    assert_equal "New IncomeTemplate", income_template.name
  end

  # Test estimated_amount validation
  test "estimated_amount should be numeric" do
    income_template = IncomeTemplate.new(user: users(:one), name: "Test", frequency: "monthly", estimated_amount: "not_a_number")
    assert_not income_template.valid?
    assert_includes income_template.errors[:estimated_amount], "is not a number"
  end

  test "estimated_amount should be greater than or equal to 0" do
    income_template = IncomeTemplate.new(user: users(:one), name: "Test", frequency: "monthly", estimated_amount: -100)
    assert_not income_template.valid?
    assert_includes income_template.errors[:estimated_amount], "must be greater than or equal to 0"
  end

  test "estimated_amount can be zero" do
    income_template = IncomeTemplate.new(user: users(:one), name: "Test", frequency: "monthly", estimated_amount: 0)
    assert income_template.valid?
  end

  test "estimated_amount can be decimal" do
    income_template = IncomeTemplate.new(user: users(:one), name: "Test", frequency: "monthly", estimated_amount: 1234.56)
    assert income_template.save
    assert_equal 1234.56, income_template.estimated_amount
  end

  # Test frequency validation
  test "frequency should be included in FREQUENCIES" do
    income_template = IncomeTemplate.new(user: users(:one), name: "Test", frequency: "invalid", estimated_amount: 100)
    assert_not income_template.valid?
    assert_includes income_template.errors[:frequency], "is not included in the list"
  end

  test "should accept valid frequencies" do
    IncomeTemplate::FREQUENCIES.each do |frequency|
      income_template = IncomeTemplate.new(user: users(:one), name: "Test #{frequency}", frequency: frequency, estimated_amount: 100)
      assert income_template.valid?, "Frequency #{frequency} should be valid"
    end
  end

  test "frequency should default to monthly" do
    income_template = IncomeTemplate.new(user: users(:one), name: "Test", estimated_amount: 100)
    assert_equal "monthly", income_template.frequency
  end

  # Test uniqueness constraint
  test "should enforce unique name per user among active templates" do
    user = users(:one)
    IncomeTemplate.create!(user: user, name: "Unique IncomeTemplate Source", frequency: "monthly", estimated_amount: 100)
    
    duplicate = IncomeTemplate.new(user: user, name: "Unique IncomeTemplate Source", frequency: "monthly", estimated_amount: 200)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "different users can have incomes with same name" do
    user1 = users(:one)
    user2 = users(:two)
    
    # Use a unique name that doesn't conflict with fixtures
    income_template1 = IncomeTemplate.create!(user: user1, name: "Shared IncomeTemplate Name", frequency: "monthly", estimated_amount: 100)
    income_template2 = IncomeTemplate.new(user: user2, name: "Shared IncomeTemplate Name", frequency: "monthly", estimated_amount: 200)
    
    assert income_template2.valid?
    assert income_template2.save
    assert_equal "Shared IncomeTemplate Name", income_template1.name
    assert_equal "Shared IncomeTemplate Name", income_template2.name
  end

  # Test soft deletion
  test "soft_delete! should set deleted_at timestamp" do
    income_template = IncomeTemplate.create!(user: users(:one), name: "To Delete", frequency: "monthly", estimated_amount: 100)
    assert_nil income_template.deleted_at
    
    income_template.soft_delete!
    income_template.reload
    assert_not_nil income_template.deleted_at
    assert income_template.deleted?
    assert_not income_template.active?
  end

  test "restore! should clear deleted_at" do
    income_template = IncomeTemplate.create!(user: users(:one), name: "To Restore", frequency: "monthly", estimated_amount: 100)
    income_template.soft_delete!
    assert income_template.deleted?
    
    income_template.restore!
    income_template.reload
    assert_nil income_template.deleted_at
    assert_not income_template.deleted?
    assert income_template.active?
  end

  test "deleted scope should return only deleted templates" do
    active_template = IncomeTemplate.create!(user: users(:one), name: "Active", frequency: "monthly", estimated_amount: 100)
    deleted_template = IncomeTemplate.create!(user: users(:one), name: "Deleted", frequency: "monthly", estimated_amount: 100)
    deleted_template.soft_delete!
    
    deleted_templates = IncomeTemplate.with_deleted.deleted
    assert_includes deleted_templates, deleted_template
    assert_not_includes deleted_templates, active_template
  end

  test "default scope should exclude deleted templates" do
    active_template = IncomeTemplate.create!(user: users(:one), name: "Active 2", frequency: "monthly", estimated_amount: 100)
    deleted_template = IncomeTemplate.create!(user: users(:one), name: "Deleted 2", frequency: "monthly", estimated_amount: 100)
    deleted_template.soft_delete!
    
    all_templates = IncomeTemplate.all
    assert_includes all_templates, active_template
    assert_not_includes all_templates, deleted_template
  end

  test "active scope should return only active templates" do
    active_template = IncomeTemplate.create!(user: users(:one), name: "Active 3", frequency: "monthly", estimated_amount: 100)
    deleted_template = IncomeTemplate.create!(user: users(:one), name: "Deleted 3", frequency: "monthly", estimated_amount: 100)
    deleted_template.soft_delete!
    
    active_templates = IncomeTemplate.active
    assert_includes active_templates, active_template
    assert_not_includes active_templates, deleted_template
  end

  test "should allow same name for active and deleted templates for same user" do
    active_template = IncomeTemplate.create!(user: users(:one), name: "Shared Name", frequency: "monthly", estimated_amount: 100)
    active_template.soft_delete!
    
    # Should be able to create a new active template with the same name
    new_active_template = IncomeTemplate.create!(user: users(:one), name: "Shared Name", frequency: "monthly", estimated_amount: 100)
    assert new_active_template.valid?
    assert new_active_template.persisted?
  end

  # Test edge cases
  test "should handle very large amounts" do
    income_template = IncomeTemplate.new(user: users(:one), name: "Large IncomeTemplate", frequency: "monthly", estimated_amount: 999999999.99)
    assert income_template.valid?
  end

  test "name can contain special characters" do
    income_template = IncomeTemplate.new(user: users(:one), name: "IncomeTemplate $1000+", frequency: "monthly", estimated_amount: 1000)
    assert income_template.valid?
  end

  # Test last_payment_to_next_month
  test "last_payment_to_next_month defaults to false" do
    income_template = IncomeTemplate.new(user: users(:one), name: "Test IncomeTemplate", frequency: "monthly", estimated_amount: 100)
    assert_equal false, income_template.last_payment_to_next_month
  end

  test "can set last_payment_to_next_month to true" do
    income_template = IncomeTemplate.create!(user: users(:one), name: "Deferred IncomeTemplate", frequency: "bi_weekly", estimated_amount: 100, last_payment_to_next_month: true)
    assert_equal true, income_template.last_payment_to_next_month
    assert income_template.last_payment_to_next_month?
  end

  # Test events_for_month method
  test "events_for_month returns empty array when auto_create is false" do
    income_template = IncomeTemplate.create!(user: users(:one), name: "Manual IncomeTemplate", frequency: "monthly", estimated_amount: 100, auto_create: false)
    assert_equal [], income_template.events_for_month("2025-12")
  end

  test "events_for_month returns empty array when due_date is nil" do
    # When auto_create is true but due_date is nil, events_for_month should return empty array
    # (Validation prevents creating such records, but method should handle nil gracefully)
    income_template = IncomeTemplate.new(user: users(:one), name: "No Date IncomeTemplate", frequency: "monthly", estimated_amount: 100, auto_create: true, due_date: nil)
    assert_equal [], income_template.events_for_month("2025-12")
  end

  test "events_for_month returns one event for monthly frequency" do
    income_template = IncomeTemplate.create!(
      user: users(:one),
      name: "Monthly IncomeTemplate",
      frequency: "monthly",
      estimated_amount: 100,
      auto_create: true,
      due_date: Date.parse("2025-12-15")
    )
    events = income_template.events_for_month("2025-12")
    assert_equal 1, events.count
    assert_equal Date.parse("2025-12-15"), events.first
  end

  test "events_for_month returns multiple events for bi_weekly frequency" do
    income_template = IncomeTemplate.create!(
      user: users(:one),
      name: "Bi-weekly IncomeTemplate",
      frequency: "bi_weekly",
      estimated_amount: 100,
      auto_create: true,
      due_date: Date.parse("2025-12-01")
    )
    events = income_template.events_for_month("2025-12")
    assert events.count >= 2, "Bi-weekly should have at least 2 events in December"
    assert events.all? { |d| d.is_a?(Date) }
  end

  test "events_for_month returns multiple events for weekly frequency" do
    income_template = IncomeTemplate.create!(
      user: users(:one),
      name: "Weekly IncomeTemplate",
      frequency: "weekly",
      estimated_amount: 100,
      auto_create: true,
      due_date: Date.parse("2025-12-01")
    )
    events = income_template.events_for_month("2025-12")
    assert events.count >= 4, "Weekly should have at least 4 events in December"
    assert events.all? { |d| d.is_a?(Date) }
  end

  # Test expected_amount_for_month method
  test "expected_amount_for_month calculates correctly for monthly" do
    income_template = IncomeTemplate.create!(
      user: users(:one),
      name: "Monthly IncomeTemplate",
      frequency: "monthly",
      estimated_amount: 5000.00,
      auto_create: true,
      due_date: Date.parse("2025-12-01")
    )
    expected = income_template.expected_amount_for_month("2025-12")
    assert_equal 5000.00, expected.to_f
  end

  test "expected_amount_for_month calculates correctly for bi_weekly" do
    income_template = IncomeTemplate.create!(
      user: users(:one),
      name: "Bi-weekly IncomeTemplate",
      frequency: "bi_weekly",
      estimated_amount: 2600.00,
      auto_create: true,
      due_date: Date.parse("2025-12-01")
    )
    expected = income_template.expected_amount_for_month("2025-12")
    # December 2025 has 3 bi-weekly pays starting Dec 1
    assert expected.to_f >= 5200.00, "Should be at least 2 pays (5200)"
  end
end

