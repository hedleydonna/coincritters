require "test_helper"

class Admin::MonthlyBudgetsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:one)
    @admin.update(admin: true)
    @regular_user = users(:two)
    @regular_user.update(admin: false)
    @monthly_budget = monthly_budgets(:one)
  end

  # Test authorization
  test "should redirect non-admin users" do
    sign_in @regular_user
    get admin_monthly_budgets_path
    assert_redirected_to root_path
    assert_equal "You don't have permission to access this page.", flash[:alert]
  end

  test "should redirect unauthenticated users" do
    get admin_monthly_budgets_path
    assert_redirected_to new_user_session_path
  end

  test "should allow admin users to access monthly budgets index" do
    sign_in @admin
    get admin_monthly_budgets_path
    assert_response :success
  end

  # Test index action
  test "should list all monthly budgets" do
    sign_in @admin
    get admin_monthly_budgets_path
    assert_response :success
    assert_select "table" do
      assert_select "tr", count: MonthlyBudget.count + 1 # +1 for header row
    end
  end

  # Test show action
  test "should show monthly budget details" do
    sign_in @admin
    get admin_monthly_budget_path(@monthly_budget)
    assert_response :success
    assert_match @monthly_budget.month_year, response.body
  end

  # Test new action
  test "should show new form" do
    sign_in @admin
    get new_admin_monthly_budget_path
    assert_response :success
    assert_select "form[action=?]", admin_monthly_budgets_path
  end

  # Test create action
  test "should create monthly budget" do
    sign_in @admin
    user = users(:one)
    
    assert_difference("MonthlyBudget.count", 1) do
      post admin_monthly_budgets_path, params: {
        monthly_budget: {
          user_id: user.id,
          month_year: "2026-01",
          total_actual_income: 5000.00,
          flex_fund: 500.00,
          bank_balance: 3000.00
        }
      }
    end
    assert_redirected_to admin_monthly_budget_path(MonthlyBudget.last)
    assert_equal "Monthly budget was successfully created.", flash[:notice]
  end

  test "should not create monthly budget with invalid data" do
    sign_in @admin
    assert_no_difference("MonthlyBudget.count") do
      post admin_monthly_budgets_path, params: {
        monthly_budget: {
          month_year: "invalid-format"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # Test edit action
  test "should show edit form" do
    sign_in @admin
    get edit_admin_monthly_budget_path(@monthly_budget)
    assert_response :success
    assert_select "form[action=?]", admin_monthly_budget_path(@monthly_budget)
  end

  # Test update action
  test "should update monthly budget" do
    sign_in @admin
    patch admin_monthly_budget_path(@monthly_budget), params: {
      monthly_budget: {
        total_actual_income: 6000.00,
        flex_fund: 600.00,
        user_id: @monthly_budget.user_id,
        month_year: @monthly_budget.month_year  # Keep same month_year to avoid uniqueness conflict
      }
    }
    assert_redirected_to admin_monthly_budget_path(@monthly_budget)
    @monthly_budget.reload
    assert_equal 6000.00, @monthly_budget.total_actual_income.to_f
    assert_equal 600.00, @monthly_budget.flex_fund.to_f
  end

  # Test destroy action
  test "should delete monthly budget" do
    sign_in @admin
    budget_to_delete = monthly_budgets(:four)
    assert_difference("MonthlyBudget.count", -1) do
      delete admin_monthly_budget_path(budget_to_delete)
    end
    assert_redirected_to admin_monthly_budgets_path
    assert_equal "Monthly budget was successfully deleted.", flash[:notice]
  end

  test "delete button should have confirmation data attribute" do
    sign_in @admin
    get admin_monthly_budgets_path
    assert_response :success
    assert_select "form[action=?]", admin_monthly_budget_path(@monthly_budget) do |forms|
      forms.each do |form|
        assert_match /turbo_confirm|confirm/, form.to_s, "Delete form should have confirmation"
      end
    end
  end
end

