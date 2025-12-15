require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:one)
    @admin.update(admin: true)
    @regular_user = users(:two)
    @regular_user.update(admin: false)
  end

  # Test authorization
  test "should redirect non-admin users" do
    sign_in @regular_user
    get admin_users_path
    assert_redirected_to root_path
    assert_equal "You don't have permission to access this page.", flash[:alert]
  end

  test "should redirect unauthenticated users" do
    get admin_users_path
    assert_redirected_to new_user_session_path
  end

  test "should allow admin users to access users index" do
    sign_in @admin
    get admin_users_path
    assert_response :success
  end

  # Test index action
  test "should list all users" do
    sign_in @admin
    get admin_users_path
    assert_response :success
    assert_select "table" do
      assert_select "tr", count: User.count + 1 # +1 for header row
    end
  end

  # Test show action
  test "should show user details" do
    sign_in @admin
    get admin_user_path(@regular_user)
    assert_response :success
    assert_match @regular_user.email, response.body
  end

  # Test edit action
  test "should show edit form" do
    sign_in @admin
    get edit_admin_user_path(@regular_user)
    assert_response :success
    assert_select "form[action=?]", admin_user_path(@regular_user)
  end

  # Test update action
  test "should update user" do
    sign_in @admin
    patch admin_user_path(@regular_user), params: {
      user: {
        display_name: "Updated Name",
        email: "updated@example.com",
        admin: false
      }
    }
    assert_redirected_to admin_user_path(@regular_user)
    @regular_user.reload
    assert_equal "Updated Name", @regular_user.display_name
    assert_equal "updated@example.com", @regular_user.email
  end

  # Test destroy action
  test "should delete user" do
    sign_in @admin
    user_to_delete = User.create!(
      email: "delete_me@example.com",
      password: "password123",
      display_name: "Delete Me"
    )
    assert_difference("User.count", -1) do
      delete admin_user_path(user_to_delete)
    end
    assert_redirected_to admin_users_path
    assert_equal "User was successfully deleted.", flash[:notice]
  end

  test "delete button should have confirmation data attribute" do
    sign_in @admin
    get admin_users_path
    assert_response :success
    # Check for delete button with confirmation
    assert_select "form[action=?]", admin_user_path(@regular_user) do |forms|
      forms.each do |form|
        assert_match /turbo_confirm|confirm/, form.to_s, "Delete form should have confirmation"
      end
    end
  end

  test "delete action should cascade to associated incomes" do
    sign_in @admin
    user_with_income = User.create!(
      email: "with_income@example.com",
      password: "password123"
    )
    income_template = IncomeTemplate.create!(
      user: user_with_income,
      name: "Salary",
      frequency: "monthly",
      estimated_amount: 5000.00
    )
    
    assert_difference("IncomeTemplate.count", -1) do
      assert_difference("User.count", -1) do
        delete admin_user_path(user_with_income)
      end
    end
  end

  # Test error handling
  test "should not update user with invalid data" do
    sign_in @admin
    patch admin_user_path(@regular_user), params: {
      user: {
        email: "invalid-email", # Invalid email format
        display_name: "Test"
      }
    }
    assert_response :unprocessable_entity
  end
end

