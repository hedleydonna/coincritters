require "test_helper"

class Admin::EnvelopesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:one)
    @admin.update(admin: true)
    @regular_user = users(:two)
    @regular_user.update(admin: false)
    @envelope = envelopes(:one)
  end

  # Test authorization
  test "should redirect non-admin users" do
    sign_in @regular_user
    get admin_envelopes_path
    assert_redirected_to root_path
    assert_equal "You don't have permission to access this page.", flash[:alert]
  end

  test "should redirect unauthenticated users" do
    get admin_envelopes_path
    assert_redirected_to new_user_session_path
  end

  test "should allow admin users to access envelopes index" do
    sign_in @admin
    get admin_envelopes_path
    assert_response :success
  end

  # Test index action
  test "should list all envelopes" do
    sign_in @admin
    get admin_envelopes_path
    assert_response :success
    assert_select "table" do
      assert_select "tr", count: Envelope.count + 1 # +1 for header row
    end
  end

  # Test show action
  test "should show envelope details" do
    sign_in @admin
    get admin_envelope_path(@envelope)
    assert_response :success
    assert_match @envelope.spending_group_name, response.body
  end

  # Test new action
  test "should show new form" do
    sign_in @admin
    get new_admin_envelope_path
    assert_response :success
    assert_select "form[action=?]", admin_envelopes_path
  end

  # Test create action
  test "should create envelope" do
    sign_in @admin
    monthly_budget = monthly_budgets(:one)
    
    assert_difference("Envelope.count", 1) do
      post admin_envelopes_path, params: {
        envelope: {
          monthly_budget_id: monthly_budget.id,
          spending_group_name: "Utilities",
          group_type: "fixed",
          is_savings: false,
          allotted_amount: 150.00,
          spent_amount: 120.00
        }
      }
    end
    assert_redirected_to admin_envelope_path(Envelope.last)
    assert_equal "Envelope was successfully created.", flash[:notice]
  end

  test "should not create envelope with invalid data" do
    sign_in @admin
    assert_no_difference("Envelope.count") do
      post admin_envelopes_path, params: {
        envelope: {
          spending_group_name: ""
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # Test edit action
  test "should show edit form" do
    sign_in @admin
    get edit_admin_envelope_path(@envelope)
    assert_response :success
    assert_select "form[action=?]", admin_envelope_path(@envelope)
  end

  # Test update action
  test "should update envelope" do
    sign_in @admin
    patch admin_envelope_path(@envelope), params: {
      envelope: {
        spending_group_name: "Updated Groceries",
        allotted_amount: 600.00,
        spent_amount: 400.00,
        monthly_budget_id: @envelope.monthly_budget_id
      }
    }
    assert_redirected_to admin_envelope_path(@envelope)
    @envelope.reload
    assert_equal "Updated Groceries", @envelope.spending_group_name
    assert_equal 600.00, @envelope.allotted_amount.to_f
  end

  # Test destroy action
  test "should delete envelope" do
    sign_in @admin
    envelope_to_delete = envelopes(:five)
    assert_difference("Envelope.count", -1) do
      delete admin_envelope_path(envelope_to_delete)
    end
    assert_redirected_to admin_envelopes_path
    assert_equal "Envelope was successfully deleted.", flash[:notice]
  end

  test "delete button should have confirmation data attribute" do
    sign_in @admin
    get admin_envelopes_path
    assert_response :success
    assert_select "form[action=?]", admin_envelope_path(@envelope) do |forms|
      forms.each do |form|
        assert_match /turbo_confirm|confirm/, form.to_s, "Delete form should have confirmation"
      end
    end
  end
end

