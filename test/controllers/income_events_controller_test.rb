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

  # Test create action - unified form
  test "should create one-off income event with just_once frequency" do
    sign_in @user
    
    assert_difference("IncomeEvent.count", 1) do
      post income_events_path, params: {
        frequency: "just_once",
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

  test "should create recurring income template and auto-create events" do
    sign_in @user
    
    # Use a unique name to avoid conflicts with fixtures
    unique_name = "Monthly Salary Test #{Time.current.to_i}"
    
    # Use a due_date that's in the future to ensure event is created
    due_date = Date.today + 5.days
    
    # Creating a recurring income should create a template and events
    assert_difference("IncomeTemplate.count", 1) do
      assert_difference("IncomeEvent.count", 1) do  # Monthly creates 1 event
        post income_events_path, params: {
          frequency: "monthly",
          income_event: {
            custom_label: unique_name
          },
          due_date: due_date.to_s,  # Pass as string at top level
          estimated_amount: 5000.00  # Pass at top level
        }
      end
    end
    
    # Find the template by name instead of using .last (which might return a fixture)
    template = IncomeTemplate.find_by(name: unique_name)
    assert_not_nil template, "Template should be created with name #{unique_name}"
    assert_equal unique_name, template.name
    assert_equal "monthly", template.frequency
    
    event = IncomeEvent.last
    assert_equal template.id, event.income_template_id
    # actual_amount should be 0 if received_on is in the future
    assert_equal 0, event.actual_amount.to_f if event.received_on > Date.today
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

  test "should redirect to money_map when return_to is money_map on update" do
    sign_in @user
    event = income_events(:one)
    
    patch income_event_path(event), params: {
      income_event: {
        actual_amount: 5500.00
      },
      return_to: "money_map"
    }
    
    assert_redirected_to money_map_path(scroll_to: 'money-in-section')
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

  test "should redirect to money_map when return_to is money_map on mark_received" do
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
    
    patch mark_received_income_event_path(event), params: {
      return_to: "money_map"
    }
    
    assert_redirected_to money_map_path(scroll_to: 'money-in-section')
  end

  # Test reset_to_expected action
  test "should reset income event actual_amount to 0" do
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
      actual_amount: 2000.00
    )
    
    patch reset_to_expected_income_event_path(event)
    
    assert_redirected_to income_events_path
    event.reload
    assert_equal 0, event.actual_amount.to_f
  end

  # Deferral functionality removed - replaced with automatic carryover
  # Test removed as toggle_defer action no longer exists

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

