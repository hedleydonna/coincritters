require "test_helper"

class Admin::VariableSpendingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:one)
    @admin.update(admin: true)
    @regular_user = users(:two)
    @regular_user.update(admin: false)
    @variable_spending = variable_spending(:one)
  end

  # Test authorization
  test "should redirect non-admin users" do
    sign_in @regular_user
    get admin_variable_spendings_path
    assert_redirected_to root_path
    assert_equal "You don't have permission to access this page.", flash[:alert]
  end

  test "should redirect unauthenticated users" do
    get admin_variable_spendings_path
    assert_redirected_to new_user_session_path
  end

  test "should allow admin users to access variable spendings index" do
    sign_in @admin
    get admin_variable_spendings_path
    assert_response :success
  end

  # Test index action
  test "should list all variable spendings" do
    sign_in @admin
    get admin_variable_spendings_path
    assert_response :success
    assert_select "table" do
      assert_select "tr", count: VariableSpending.count + 1 # +1 for header row
    end
  end

  # Test show action
  test "should show variable spending details" do
    sign_in @admin
    get admin_variable_spending_path(@variable_spending)
    assert_response :success
    assert_match @variable_spending.spending_group_name, response.body
  end

  # Test new action
  test "should show new form" do
    sign_in @admin
    get new_admin_variable_spending_path
    assert_response :success
    assert_select "form[action=?]", admin_variable_spendings_path
  end

  # Test create action
  test "should create variable spending" do
    sign_in @admin
    envelope = envelopes(:one)
    
    assert_difference("VariableSpending.count", 1) do
      post admin_variable_spendings_path, params: {
        variable_spending: {
          envelope_id: envelope.id,
          spending_group_name: "Groceries",
          amount: 65.50,
          spent_on: Date.today,
          notes: "Test spending"
        }
      }
    end
    assert_redirected_to admin_variable_spending_path(VariableSpending.last)
    assert_equal "Variable spending was successfully created.", flash[:notice]
  end

  test "should not create variable spending with invalid data" do
    sign_in @admin
    assert_no_difference("VariableSpending.count") do
      post admin_variable_spendings_path, params: {
        variable_spending: {
          spending_group_name: "",
          amount: 0
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # Test edit action
  test "should show edit form" do
    sign_in @admin
    get edit_admin_variable_spending_path(@variable_spending)
    assert_response :success
    assert_select "form[action=?]", admin_variable_spending_path(@variable_spending)
  end

  # Test update action
  test "should update variable spending" do
    sign_in @admin
    patch admin_variable_spending_path(@variable_spending), params: {
      variable_spending: {
        spending_group_name: "Updated Groceries",
        amount: 85.00,
        spent_on: @variable_spending.spent_on,
        envelope_id: @variable_spending.envelope_id
      }
    }
    assert_redirected_to admin_variable_spending_path(@variable_spending)
    @variable_spending.reload
    assert_equal "Updated Groceries", @variable_spending.spending_group_name
    assert_equal 85.00, @variable_spending.amount.to_f
  end

  # Test destroy action
  test "should delete variable spending" do
    sign_in @admin
    variable_spending_to_delete = variable_spending(:five)
    assert_difference("VariableSpending.count", -1) do
      delete admin_variable_spending_path(variable_spending_to_delete)
    end
    assert_redirected_to admin_variable_spendings_path
    assert_equal "Variable spending was successfully deleted.", flash[:notice]
  end

  test "delete button should have confirmation data attribute" do
    sign_in @admin
    get admin_variable_spendings_path
    assert_response :success
    assert_select "form[action=?]", admin_variable_spending_path(@variable_spending) do |forms|
      forms.each do |form|
        assert_match /turbo_confirm|confirm/, form.to_s, "Delete form should have confirmation"
      end
    end
  end
end

