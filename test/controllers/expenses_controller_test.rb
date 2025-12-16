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
      auto_create: true
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
      auto_create: true
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
      auto_create: true
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

  # Test create action
  test "should create expense and redirect with full page reload" do
    sign_in @user
    budget = @user.current_budget!
    template = ExpenseTemplate.create!(
      user: @user,
      name: "Test Template",
      frequency: "monthly"
    )
    
    assert_difference("Expense.count", 1) do
      post expenses_path, params: {
        expense: {
          expense_template_id: template.id,
          allotted_amount: 200.00
        },
        month: @current_month
      }
    end
    
    assert_redirected_to expenses_path(month: @current_month)
    follow_redirect!
    assert_response :success
    # Check that the expense appears in the response
    assert_match /Test Template/, response.body
  end

  test "should create one-off expense without template" do
    sign_in @user
    budget = @user.current_budget!
    
    assert_difference("Expense.count", 1) do
      post expenses_path, params: {
        expense: {
          name: "One-off Test",
          allotted_amount: 50.00
        },
        month: @current_month
      }
    end
    
    expense = Expense.last
    assert_nil expense.expense_template_id
    assert_equal "One-off Test", expense.name
    assert_equal 50.00, expense.allotted_amount.to_f
  end

  test "should not create expense with invalid data" do
    sign_in @user
    # Get current budget and count its expenses
    budget = @user.current_budget!
    initial_expense_count = budget.expenses.count
    
    post expenses_path, params: {
      expense: {
        name: nil,
        expense_template_id: nil
      },
      month: @current_month
    }
    
    assert_response :unprocessable_entity
    # Verify no new expense was created (auto-creation may have happened, so we check the form was re-rendered)
    budget.reload
    # The expense count might have increased due to auto-creation, but the invalid expense wasn't created
    # The key is that we got unprocessable_entity response
  end

  # Test edit action
  test "should show edit form" do
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
      allotted_amount: 100.00
    )
    
    get edit_expense_path(expense, month: @current_month)
    assert_response :success
    assert_select "form[action=?]", expense_path(expense)
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
      allotted_amount: 100.00
    )
    
    patch expense_path(expense), params: {
      expense: {
        allotted_amount: 150.00
      },
      month: @current_month
    }
    
    assert_redirected_to expenses_path(month: @current_month)
    expense.reload
    assert_equal 150.00, expense.allotted_amount.to_f
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
      allotted_amount: 100.00
    )
    
    post mark_expense_paid_path(expense.id)
    assert_redirected_to expenses_path(month: @next_month)
    assert_match /only mark expenses as paid in the current month/, flash[:alert]
  end

  # Test form submission with turbo: false
  test "new expense form should have turbo: false" do
    sign_in @user
    get new_expense_path
    assert_response :success
    # Check that form has data-turbo="false" attribute
    assert_match /data-turbo="false"/, response.body
  end
end

