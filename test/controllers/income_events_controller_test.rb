require "test_helper"

class IncomeEventsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @current_month = Time.current.strftime("%Y-%m")
    @next_month = (Date.today + 1.month).strftime("%Y-%m")
  end

  # Test authentication
  test "should require authentication to access income events" do
    # Income events route is inside authenticated block, so unauthenticated users get 404
    get income_events_path
    assert_response :not_found
  end

  # Test index action
  test "should allow authenticated users to access income events index" do
    sign_in @user
    get income_events_path
    assert_response :success
  end

  test "should only allow viewing current or next month" do
    sign_in @user
    past_month = (Date.today - 1.month).strftime("%Y-%m")
    
    get income_events_path(month: past_month)
    assert_redirected_to income_events_path
    assert_match /You can only view current or next month/, flash[:alert]
  end

  test "should auto-create income events from templates when viewing" do
    sign_in @user
    template = IncomeTemplate.create!(
      user: @user,
      name: "Test Income Template",
      frequency: "monthly",
      estimated_amount: 1000.00,
      auto_create: true,
      due_date: Date.today
    )
    
    budget = @user.current_budget!
    # Remove any existing events for this template
    @user.income_events.where(income_template_id: template.id).destroy_all
    
    initial_count = @user.income_events.count
    
    get income_events_path
    
    @user.income_events.reload
    assert @user.income_events.count >= initial_count + 1
    assert @user.income_events.exists?(income_template_id: template.id)
  end

  # Test new action
  test "should show new income event form" do
    sign_in @user
    get new_income_event_path
    assert_response :success
    assert_select "form[action=?]", income_events_path
  end

  # Test create action
  test "should create one-off income event" do
    sign_in @user
    
    assert_difference("IncomeEvent.count", 1) do
      post income_events_path, params: {
        income_event: {
          custom_label: "Gift",
          received_on: Date.today,
          actual_amount: 100.00,
          notes: "Birthday gift"
        }
      }
    end
    
    event = IncomeEvent.last
    assert_nil event.income_template_id
    assert_equal "Gift", event.custom_label
    assert_equal 100.00, event.actual_amount.to_f
  end

  # Test edit action
  test "should show edit form" do
    sign_in @user
    event = income_events(:one)
    
    get edit_income_event_path(event)
    assert_response :success
    assert_select "form[action=?]", income_event_path(event)
  end

  # Test update action
  test "should update income event" do
    sign_in @user
    event = income_events(:one)
    
    patch income_event_path(event), params: {
      income_event: {
        actual_amount: 5500.00
      }
    }
    
    assert_redirected_to income_events_path
    event.reload
    assert_equal 5500.00, event.actual_amount.to_f
  end

  # Test mark_received action
  test "should mark income event as received" do
    sign_in @user
    template = IncomeTemplate.create!(
      user: @user,
      name: "Test Template",
      frequency: "monthly",
      estimated_amount: 2000.00
    )
    event = IncomeEvent.create!(
      user: @user,
      income_template: template,
      received_on: Date.today,
      month_year: @current_month,
      actual_amount: 0
    )
    
    patch mark_received_income_event_path(event)
    
    assert_redirected_to income_events_path
    event.reload
    assert_equal 2000.00, event.actual_amount.to_f
  end

  # Test toggle_defer action
  test "should toggle deferral status" do
    sign_in @user
    event = income_events(:one)
    original_status = event.apply_to_next_month
    
    patch toggle_defer_income_event_path(event)
    
    assert_redirected_to income_events_path
    event.reload
    assert_not_equal original_status, event.apply_to_next_month
  end

  # Test destroy action
  test "should delete one-off income event" do
    sign_in @user
    event = IncomeEvent.create!(
      user: @user,
      income_template_id: nil,  # One-off event
      custom_label: "One-off Income",
      received_on: Date.today,
      month_year: @current_month,
      actual_amount: 100.00
    )
    
    assert_difference("IncomeEvent.count", -1) do
      delete income_event_path(event)
    end
    
    assert_redirected_to income_events_path
    assert_match /Income event removed/, flash[:notice]
    assert_match /\$100.00/, flash[:notice]
    assert_not IncomeEvent.exists?(event.id)
  end

  test "should not delete template-based income event" do
    sign_in @user
    template = IncomeTemplate.create!(
      user: @user,
      name: "Test Template",
      frequency: "monthly",
      estimated_amount: 1000.00
    )
    event = IncomeEvent.create!(
      user: @user,
      income_template: template,
      received_on: Date.today,
      month_year: @current_month,
      actual_amount: 1000.00
    )
    
    assert_no_difference("IncomeEvent.count") do
      delete income_event_path(event)
    end
    
    assert_redirected_to income_events_path
    assert_match /Cannot delete income events created from templates/, flash[:alert]
    assert IncomeEvent.exists?(event.id)
  end
end

