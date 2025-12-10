require "test_helper"

class Admin::IncomeEventsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:one)
    @admin.update(admin: true)
    @regular_user = users(:two)
    @regular_user.update(admin: false)
    @income_event = income_events(:one)
  end

  # Test authorization
  test "should redirect non-admin users" do
    sign_in @regular_user
    get admin_income_events_path
    assert_redirected_to root_path
    assert_equal "You don't have permission to access this page.", flash[:alert]
  end

  test "should redirect unauthenticated users" do
    get admin_income_events_path
    assert_redirected_to new_user_session_path
  end

  test "should allow admin users to access income events index" do
    sign_in @admin
    get admin_income_events_path
    assert_response :success
  end

  # Test index action
  test "should list all income events" do
    sign_in @admin
    get admin_income_events_path
    assert_response :success
    assert_select "table" do
      assert_select "tr", count: IncomeEvent.count + 1 # +1 for header row
    end
  end

  # Test show action
  test "should show income event details" do
    sign_in @admin
    get admin_income_event_path(@income_event)
    assert_response :success
    assert_match @income_event.month_year, response.body
  end

  # Test new action
  test "should show new form" do
    sign_in @admin
    get new_admin_income_event_path
    assert_response :success
    assert_select "form[action=?]", admin_income_events_path
  end

  # Test create action
  test "should create income event" do
    sign_in @admin
    user = users(:one)
    
    assert_difference("IncomeEvent.count", 1) do
      post admin_income_events_path, params: {
        income_event: {
          user_id: user.id,
          custom_label: "Bonus",
          month_year: "2025-12",
          received_on: Date.today,
          actual_amount: 1000.00
        }
      }
    end
    assert_redirected_to admin_income_event_path(IncomeEvent.last)
    assert_equal "Income event was successfully created.", flash[:notice]
  end

  test "should not create income event with invalid data" do
    sign_in @admin
    assert_no_difference("IncomeEvent.count") do
      post admin_income_events_path, params: {
        income_event: {
          month_year: "invalid-format"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # Test edit action
  test "should show edit form" do
    sign_in @admin
    get edit_admin_income_event_path(@income_event)
    assert_response :success
    assert_select "form[action=?]", admin_income_event_path(@income_event)
  end

  # Test update action
  test "should update income event" do
    sign_in @admin
    patch admin_income_event_path(@income_event), params: {
      income_event: {
        month_year: "2025-11",
        actual_amount: 6000.00,
        received_on: "2025-11-15",
        user_id: @income_event.user_id,
        custom_label: "Updated Type"
      }
    }
    assert_redirected_to admin_income_event_path(@income_event)
    @income_event.reload
    assert_equal "2025-11", @income_event.month_year
    assert_equal 6000.00, @income_event.actual_amount.to_f
    assert_equal "Updated Type", @income_event.custom_label
  end

  # Test destroy action
  test "should delete income event" do
    sign_in @admin
    income_event_to_delete = IncomeEvent.create!(
      user: @regular_user,
      custom_label: "Test Type",
      month_year: "2025-12",
      received_on: Date.today,
      actual_amount: 1000.00
    )
    assert_difference("IncomeEvent.count", -1) do
      delete admin_income_event_path(income_event_to_delete)
    end
    assert_redirected_to admin_income_events_path
    assert_equal "Income event was successfully deleted.", flash[:notice]
  end

  test "delete button should have confirmation data attribute" do
    sign_in @admin
    get admin_income_events_path
    assert_response :success
    assert_select "form[action=?]", admin_income_event_path(@income_event) do |forms|
      forms.each do |form|
        assert_match /turbo_confirm|confirm/, form.to_s, "Delete form should have confirmation"
      end
    end
  end
end

