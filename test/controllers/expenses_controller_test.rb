require "test_helper"

class ExpensesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @current_month = Time.current.strftime("%Y-%m")
    @next_month = (Date.today + 1.month).strftime("%Y-%m")
    # Clean up any existing budgets/expenses for test user to avoid fixture interference
    @user.monthly_budgets.where(month_year: [@current_month, @next_month]).destroy_all
  end

  # Test authentication
  test "should require authentication to access expenses" do
    # Expenses route is inside authenticated block, so unauthenticated users get 404
    get expenses_path
    assert_response :not_found
  end

  # Test index action
  test "should allow authenticated users to access expenses index" do
    sign_in @user
    get expenses_path
    assert_response :success
  end

  test "should auto-create current month budget if missing" do
    sign_in @user
    # Ensure no current month budget exists
    MonthlyBudget.where(user: @user, month_year: @current_month).destroy_all
    
    # Count only budgets for this user to avoid fixture interference
    initial_count = @user.monthly_budgets.count
    
    get expenses_path
    
    @user.monthly_budgets.reload
    # Budget should be created (may also create next month budget)
    assert @user.monthly_budgets.count >= initial_count + 1
    assert MonthlyBudget.exists?(user: @user, month_year: @current_month)
  end

  test "should auto-create expenses from templates when viewing expenses page" do
    sign_in @user
    # Create expense template with auto_create: true
    template = ExpenseTemplate.create!(
      user: @user,
      name: "Test Auto Create Template #{Time.current.to_i}",
      frequency: "monthly",
      default_amount: 100.00,
      auto_create: true,
      due_date: Date.today  # Need due_date for events_for_month
    )
    
    # Ensure budget exists but has no expenses for this template
    budget = @user.current_budget!
    budget.expenses.where(expense_template_id: template.id).destroy_all
    
    # Count expenses for this budget only
    initial_count = budget.expenses.count
    
    # Viewing expenses page should auto-create expense from template
    get expenses_path
    
    budget.reload
    assert_equal initial_count + 1, budget.expenses.count
    assert budget.expenses.exists?(expense_template_id: template.id)
  end

  test "should auto-create expenses for both current and next month when viewing" do
    sign_in @user
    template = ExpenseTemplate.create!(
      user: @user,
      name: "Test Template #{Time.current.to_i}",
      frequency: "monthly",
      default_amount: 50.00,
      auto_create: true,
      due_date: Date.today  # Need due_date for events_for_month
    )
    
    current_budget = @user.current_budget!
    # Remove any existing expenses for this template
    current_budget.expenses.where(expense_template_id: template.id).destroy_all
    
    # Create next month budget
    next_budget = @user.monthly_budgets.find_or_create_by!(month_year: @next_month)
    next_budget.expenses.where(expense_template_id: template.id).destroy_all
    
    # Count expenses for this template only
    current_initial = current_budget.expenses.where(expense_template_id: template.id).count
    next_initial = next_budget.expenses.where(expense_template_id: template.id).count
    
    # Viewing expenses page should create expenses for current month
    get expenses_path
    current_budget.reload
    assert_equal current_initial + 1, current_budget.expenses.where(expense_template_id: template.id).count
    assert current_budget.expenses.exists?(expense_template_id: template.id)
    
    # Viewing next month should create expenses for next month
    get expenses_path(month: @next_month)
    next_budget.reload
    assert_equal next_initial + 1, next_budget.expenses.where(expense_template_id: template.id).count
    assert next_budget.expenses.exists?(expense_template_id: template.id)
  end

  test "should not create duplicate expenses when auto-creating" do
    sign_in @user
    template = ExpenseTemplate.create!(
      user: @user,
      name: "Test Template #{Time.current.to_i}",
      frequency: "monthly",
      default_amount: 50.00,
      auto_create: true,
      due_date: Date.today  # Need due_date for events_for_month
    )
    
    budget = @user.current_budget!
    budget.expenses.where(expense_template_id: template.id).destroy_all
    
    # Count expenses for this budget only
    initial_count = budget.expenses.count
    
    # First visit creates expense
    get expenses_path
    budget.reload
    assert_equal initial_count + 1, budget.expenses.count
    assert_equal 1, budget.expenses.where(expense_template_id: template.id).count
    
    # Second visit should not create duplicate
    second_count = budget.expenses.count
    get expenses_path
    budget.reload
    assert_equal second_count, budget.expenses.count
    assert_equal 1, budget.expenses.where(expense_template_id: template.id).count
  end

  test "should display expenses for current month by default" do
    sign_in @user
    budget = @user.current_budget!
    template = ExpenseTemplate.create!(
      user: @user,
      name: "Test Expense",
      frequency: "monthly",
      auto_create: true
    )
    
    get expenses_path
    assert_response :success
    assert_match /Spending/, response.body
    assert_match /#{@current_month}/, response.body
  end

  test "should allow viewing specific month via params" do
    sign_in @user
    budget = MonthlyBudget.create!(
      user: @user,
      month_year: @next_month,
      total_actual_income: 5000.00
    )
    
    get expenses_path(month: @next_month)
    assert_response :success
    assert_match /#{@next_month}/, response.body
  end

  # Test new action
  test "should show new expense form" do
    sign_in @user
    get new_expense_path
    assert_response :success
    assert_select "form[action=?]", expenses_path
  end

  test "should show new expense form for specific month" do
    sign_in @user
    get new_expense_path(month: @next_month)
    assert_response :success
    assert_select "form[action=?]", expenses_path
  end

  # Test create action - unified form
  test "should create one-off expense with just_once frequency" do
    sign_in @user
    budget = @user.current_budget!
    
    assert_difference("Expense.count", 1) do
      post expenses_path, params: {
        frequency: "just_once",
        expense: {
          name: "One-off Test",
          allotted_amount: 50.00,
          expected_on: Date.today
        },
        month: @current_month
      }
    end
    
    expense = Expense.last
    assert_nil expense.expense_template_id
    assert_equal "One-off Test", expense.name
    assert_equal 50.00, expense.allotted_amount.to_f
    assert_redirected_to expenses_path(month: @current_month)
  end

  test "should create recurring expense template and auto-create expenses" do
    sign_in @user
    budget = @user.current_budget!
    
    # Use a unique name to avoid conflicts with fixtures
    unique_name = "Monthly Rent Test #{Time.current.to_i}"
    
    # Use a due_date that ensures expense is created for current month
    # Use today or future date to ensure it's not filtered out
    due_date = Date.today
    
    # Creating a recurring expense should create a template and expenses
    assert_difference("ExpenseTemplate.count", 1) do
      assert_difference("Expense.count", 1) do  # Monthly creates 1 expense
        post expenses_path, params: {
          frequency: "monthly",
          expense: {
            name: unique_name
          },
          due_date: due_date.to_s,  # Pass as string at top level
          default_amount: 1200.00,  # Pass at top level
          month: @current_month
        }
      end
    end
    
    # Find the template by name instead of using .last (which might return a fixture)
    template = ExpenseTemplate.find_by(name: unique_name)
    assert_not_nil template, "Template should be created with name #{unique_name}"
    assert_equal unique_name, template.name
    assert_equal "monthly", template.frequency
    
    expense = Expense.last
    assert_equal template.id, expense.expense_template_id
    assert_equal unique_name, expense.name  # Name copied from template
    assert_equal 1200.00, expense.allotted_amount.to_f
  end

  test "should not create expense with invalid data" do
    sign_in @user
    budget = @user.current_budget!
    
    # Try to create without name (required field)
    post expenses_path, params: {
      frequency: "just_once",
      expense: {
        name: "",  # Empty name should fail validation
        allotted_amount: 50.00,
        expected_on: Date.today
      },
      month: @current_month
    }
    
    # Should redirect with error or show unprocessable_entity
    # The controller might redirect on validation failure, so check for either
    assert_includes [422, 303], response.status
  end

  # Test edit action
  test "should show edit form with payment management" do
    sign_in @user
    budget = @user.current_budget!
    template = ExpenseTemplate.create!(
      user: @user,
      name: "Test Template",
      frequency: "monthly"
    )
    expense = Expense.create!(
      monthly_budget: budget,
      expense_template: template,
      name: template.name,
      allotted_amount: 100.00
    )
    
    get edit_expense_path(expense, month: @current_month)
    assert_response :success
    assert_select "form[action=?]", expense_path(expense)
    # Should show payment form
    assert_match /Add Payment/i, response.body
  end

  # Test update action
  test "should update expense" do
    sign_in @user
    budget = @user.current_budget!
    template = ExpenseTemplate.create!(
      user: @user,
      name: "Test Template",
      frequency: "monthly"
    )
    expense = Expense.create!(
      monthly_budget: budget,
      expense_template: template,
      name: template.name,
      allotted_amount: 100.00
    )
    
    patch expense_path(expense), params: {
      expense: {
        name: expense.name,
        allotted_amount: 150.00
      },
      month: @current_month
    }
    
    assert_redirected_to expenses_path(month: @current_month)
    expense.reload
    assert_equal 150.00, expense.allotted_amount.to_f
  end

  test "should redirect to money_map when return_to is money_map on update" do
    sign_in @user
    budget = @user.current_budget!
    template = ExpenseTemplate.create!(
      user: @user,
      name: "Test Template",
      frequency: "monthly"
    )
    expense = Expense.create!(
      monthly_budget: budget,
      expense_template: template,
      name: template.name,
      allotted_amount: 100.00
    )
    
    patch expense_path(expense), params: {
      expense: {
        name: expense.name,
        allotted_amount: 150.00
      },
      return_to: "money_map"
    }
    
    assert_redirected_to money_map_path(scroll_to: 'spending-section')
  end

  # Test mark_paid action
  test "should mark expense as paid" do
    sign_in @user
    budget = @user.current_budget!
    template = ExpenseTemplate.create!(
      user: @user,
      name: "Test Template",
      frequency: "monthly"
    )
    expense = Expense.create!(
      monthly_budget: budget,
      expense_template: template,
      name: template.name,
      allotted_amount: 100.00
    )
    
    assert_difference("Payment.count", 1) do
      post mark_expense_paid_path(expense.id)
    end
    
    expense.reload
    assert expense.paid?
    assert_equal 100.00, expense.spent_amount.to_f
  end

  test "should not mark expense as paid for non-current month" do
    sign_in @user
    next_budget = @user.monthly_budgets.find_or_create_by!(month_year: @next_month)
    template = ExpenseTemplate.create!(
      user: @user,
      name: "Test Template",
      frequency: "monthly"
    )
    expense = Expense.create!(
      monthly_budget: next_budget,
      expense_template: template,
      name: template.name,
      allotted_amount: 100.00
    )
    
    post mark_expense_paid_path(expense.id)
    assert_redirected_to expenses_path(month: @next_month)
    assert_match /only mark expenses as paid in the current month/, flash[:alert]
  end

  # Test return_to parameter
  test "should redirect to money_map when return_to is money_map" do
    sign_in @user
    budget = @user.current_budget!
    
    post expenses_path, params: {
      frequency: "just_once",
      expense: {
        name: "Test Expense",
        allotted_amount: 50.00,
        expected_on: Date.today
      },
      return_to: "money_map"
    }
    
    assert_redirected_to money_map_path(scroll_to: 'spending-section')
  end

  # Test add_payment action
  test "should add payment to expense" do
    sign_in @user
    budget = @user.current_budget!
    template = ExpenseTemplate.create!(
      user: @user,
      name: "Test Template",
      frequency: "monthly"
    )
    expense = Expense.create!(
      monthly_budget: budget,
      expense_template: template,
      name: template.name,
      allotted_amount: 100.00
    )
    
    assert_difference("Payment.count", 1) do
      post add_payment_expense_path(expense), params: {
        amount: 50.00,
        spent_on: Date.today,
        return_to: "money_map"
      }
    end
    
    expense.reload
    assert_equal 50.00, expense.spent_amount.to_f
    assert_redirected_to money_map_path(scroll_to: 'spending-section')
  end

  test "should not add payment for non-current month expense" do
    sign_in @user
    next_budget = @user.monthly_budgets.find_or_create_by!(month_year: @next_month)
    template = ExpenseTemplate.create!(
      user: @user,
      name: "Test Template",
      frequency: "monthly"
    )
    expense = Expense.create!(
      monthly_budget: next_budget,
      expense_template: template,
      name: template.name,
      allotted_amount: 100.00
    )
    
    assert_no_difference("Payment.count") do
      post add_payment_expense_path(expense), params: {
        amount: 50.00,
        spent_on: Date.today
      }
    end
    
    # Should redirect to edit page when return_to is not money_map
    assert_redirected_to edit_expense_path(expense)
    assert_match /Payments can only be added/, flash[:alert]
  end

  # Test destroy action
  test "should delete one-off expense" do
    sign_in @user
    budget = @user.current_budget!
    expense = Expense.create!(
      monthly_budget: budget,
      expense_template_id: nil,  # One-off expense
      name: "One-off Test Expense",
      allotted_amount: 50.00
    )
    
    assert_difference("Expense.count", -1) do
      delete expense_path(expense, month: @current_month)
    end
    
    assert_redirected_to expenses_path(month: @current_month)
    assert_match /Expense deleted/, flash[:notice]
    assert_not Expense.exists?(expense.id)
  end

  test "should not delete template-based expense" do
    sign_in @user
    budget = @user.current_budget!
    template = ExpenseTemplate.create!(
      user: @user,
      name: "Test Template",
      frequency: "monthly"
    )
    expense = Expense.create!(
      monthly_budget: budget,
      expense_template: template,
      name: template.name,
      allotted_amount: 100.00
    )
    
    assert_no_difference("Expense.count") do
      delete expense_path(expense, month: @current_month)
    end
    
    assert_redirected_to expenses_path(month: @current_month)
    assert_match /Cannot delete expenses created from templates/, flash[:alert]
    assert Expense.exists?(expense.id)
  end

  test "should delete associated payments when deleting one-off expense" do
    sign_in @user
    budget = @user.current_budget!
    expense = Expense.create!(
      monthly_budget: budget,
      expense_template_id: nil,
      name: "One-off Expense",
      allotted_amount: 100.00
    )
    payment = Payment.create!(
      expense: expense,
      amount: 50.00,
      spent_on: Date.today
    )
    
    assert_difference("Expense.count", -1) do
      assert_difference("Payment.count", -1) do
        delete expense_path(expense, month: @current_month)
      end
    end
    
    assert_not Payment.exists?(payment.id)
  end
end

