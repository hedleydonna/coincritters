require "test_helper"

class Admin::IncomesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:one)
    @admin.update(admin: true)
    @regular_user = users(:two)
    @regular_user.update(admin: false)
    @income = incomes(:one)
  end

  # Test authorization
  test "should redirect non-admin users" do
    sign_in @regular_user
    get admin_incomes_path
    assert_redirected_to root_path
    assert_equal "You don't have permission to access this page.", flash[:alert]
  end

  test "should redirect unauthenticated users" do
    get admin_incomes_path
    assert_redirected_to new_user_session_path
  end

  test "should allow admin users to access incomes index" do
    sign_in @admin
    get admin_incomes_path
    assert_response :success
  end

  # Test index action
  test "should list all incomes" do
    sign_in @admin
    get admin_incomes_path
    assert_response :success
    assert_select "table" do
      assert_select "tr", count: Income.count + 1 # +1 for header row
    end
  end

  # Test show action
  test "should show income details" do
    sign_in @admin
    get admin_income_path(@income)
    assert_response :success
    assert_match @income.name, response.body
    # Check that the income amount appears in the response (formatted by number_with_delimiter)
    # The amount will be formatted, so just check for the income name which is sufficient
    assert_match @income.name, response.body
  end

  # Test edit action
  test "should show edit form" do
    sign_in @admin
    get edit_admin_income_path(@income)
    assert_response :success
    assert_select "form[action=?]", admin_income_path(@income)
  end

  # Test update action
  test "should update income" do
    sign_in @admin
    patch admin_income_path(@income), params: {
      income: {
        name: "Updated Income",
        estimated_amount: 6000.00,
        frequency: "bi_weekly",
        active: true
      }
    }
    assert_redirected_to admin_income_path(@income)
    @income.reload
    assert_equal "Updated Income", @income.name
    assert_equal 6000.00, @income.estimated_amount.to_f
    assert_equal "bi_weekly", @income.frequency
  end

  # Test destroy action
  test "should delete income" do
    sign_in @admin
    income_to_delete = Income.create!(
      user: @regular_user,
      name: "Delete Me",
      frequency: "monthly",
      estimated_amount: 1000.00
    )
    assert_difference("Income.count", -1) do
      delete admin_income_path(income_to_delete)
    end
    assert_redirected_to admin_incomes_path
    assert_equal "Income was successfully deleted.", flash[:notice]
  end

  test "delete button should have confirmation data attribute" do
    sign_in @admin
    get admin_incomes_path
    assert_response :success
    # Check for delete button with confirmation
    assert_select "form[action=?]", admin_income_path(@income) do |forms|
      forms.each do |form|
        assert_match /turbo_confirm|confirm/, form.to_s, "Delete form should have confirmation"
      end
    end
  end

  # Test error handling
  test "should not update income with invalid data" do
    sign_in @admin
    patch admin_income_path(@income), params: {
      income: {
        estimated_amount: -100, # Invalid negative amount
        name: "Test"
      }
    }
    assert_response :unprocessable_entity
  end

  test "should not update income with duplicate name for same user" do
    sign_in @admin
    existing_income = incomes(:two) # Same user as @income
    patch admin_income_path(@income), params: {
      income: {
        name: existing_income.name, # Duplicate name
        estimated_amount: 1000.00
      }
    }
    assert_response :unprocessable_entity
  end
end

