import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["recurringFields", "oneOffAmount", "oneOffDate", "amountField", "amountLabel", "amountLabelText", "amountRequired", "amountHelpText", "amountInput", "dateField", "dateLabel", "dateLabelText", "dateRequired", "dateHelpText", "dateInput", "frequencySelect"]

  connect() {
    // Check frequency select value on page load (e.g., after validation error)
    const frequencySelect = this.element.querySelector("#frequency")
    if (frequencySelect) {
      const frequency = frequencySelect.value
      this.updateFieldsBasedOnFrequency(frequency)
    } else {
      // Default to one-off if no frequency select found
      const isIncome = this.element.querySelector("input[name*='actual_amount']") || this.element.querySelector("input[name*='received_on']")
      this.updateAmountFieldForOneOff()
      if (isIncome) {
        this.updateDateFieldForOneOff()
      }
    }
  }

  toggle(event) {
    const frequency = event.target.value
    this.updateFieldsBasedOnFrequency(frequency)
  }

  updateFieldsBasedOnFrequency(frequency) {
    const isJustOnce = frequency === "just_once"
    // Determine if this is income or expense form
    const isIncome = this.element.querySelector("input[name*='actual_amount']") || this.element.querySelector("input[name*='received_on']")
    const isExpense = this.element.querySelector("input[name*='allotted_amount']")
    
    if (isJustOnce) {
      // One-off
      if (this.hasOneOffAmountTarget) {
        this.showOneOffAmount()
      }
      if (this.hasOneOffDateTarget && isIncome) {
        // Only show/hide date for income forms
        this.showOneOffDate()
      }
      this.updateAmountFieldForOneOff()
      if (isIncome) {
        this.updateDateFieldForOneOff()
      }
    } else {
      // Recurring template
      if (this.hasOneOffAmountTarget) {
        this.hideOneOffAmount()
      }
      if (this.hasOneOffDateTarget && isIncome) {
        // Only show/hide date for income forms
        this.hideOneOffDate()
      }
      this.updateAmountFieldForRecurring()
      if (isIncome) {
        this.updateDateFieldForRecurring()
      } else if (isExpense && this.hasDateFieldTarget) {
        // For expenses, just update the date label/help text but keep it visible
        this.updateDateFieldForExpenseRecurring()
      }
    }
  }

  updateAmountFieldForRecurring() {
    // Determine if this is income or expense form
    const isIncome = this.element.querySelector("input[name*='actual_amount']") || this.element.querySelector("input[name*='received_on']")
    const isExpense = this.element.querySelector("input[name*='allotted_amount']")
    
    // Update label
    if (this.hasAmountLabelTextTarget) {
      this.amountLabelTextTarget.textContent = isIncome ? "Estimated Amount" : "Default Amount"
    }
    
    // Make required indicator optional
    if (this.hasAmountRequiredTarget) {
      this.amountRequiredTarget.textContent = ""
      this.amountRequiredTarget.classList.remove("text-red-500")
      this.amountRequiredTarget.classList.add("text-gray-500", "text-xs")
      this.amountRequiredTarget.textContent = "(optional)"
    }
    
    // Update help text
    if (this.hasAmountHelpTextTarget) {
      if (isIncome) {
        this.amountHelpTextTarget.textContent = "The estimated amount you typically receive (optional - you can set this later when editing the template). When income events are automatically created, this will be used as the initial amount."
      } else {
        this.amountHelpTextTarget.textContent = "The default amount for this expense (optional - you can set this later when editing the template). When expenses are automatically created, this will be used as the allotted amount."
      }
    }
    
    // Change field name
    if (this.hasAmountInputTarget) {
      const input = this.amountInputTarget
      const value = input.value
      if (isIncome) {
        input.name = "estimated_amount"
      } else {
        input.name = "default_amount"
      }
      input.removeAttribute("required")
      input.setAttribute("min", "0")
      input.value = value // Preserve value
    }
  }

  updateAmountFieldForOneOff() {
    // Determine if this is income or expense form
    const isIncome = this.element.querySelector("input[name*='actual_amount']") || this.element.querySelector("input[name*='received_on']")
    const isExpense = this.element.querySelector("input[name*='allotted_amount']")
    
    // Update label
    if (this.hasAmountLabelTextTarget) {
      this.amountLabelTextTarget.textContent = "Amount"
    }
    
    // Make required indicator required
    if (this.hasAmountRequiredTarget) {
      this.amountRequiredTarget.textContent = "*"
      this.amountRequiredTarget.classList.remove("text-gray-500", "text-xs")
      this.amountRequiredTarget.classList.add("text-red-500")
    }
    
    // Update help text
    if (this.hasAmountHelpTextTarget) {
      if (isIncome) {
        this.amountHelpTextTarget.textContent = "The actual amount you received"
      } else {
        this.amountHelpTextTarget.textContent = "The amount you plan to spend or have spent"
      }
    }
    
    // Change field name back
    if (this.hasAmountInputTarget) {
      const input = this.amountInputTarget
      const value = input.value
      if (isIncome) {
        input.name = "income_event[actual_amount]"
        input.setAttribute("min", "0.01")
      } else {
        input.name = "expense[allotted_amount]"
        input.setAttribute("min", "0")
      }
      input.setAttribute("required", "required")
      input.value = value // Preserve value
    }
  }

  updateDateFieldForRecurring() {
    // Only for income forms
    if (!this.hasDateFieldTarget) {
      return
    }
    
    // Update label
    if (this.hasDateLabelTextTarget) {
      this.dateLabelTextTarget.textContent = "Due Date"
    }
    
    // Keep required indicator
    if (this.hasDateRequiredTarget) {
      this.dateRequiredTarget.textContent = "*"
      this.dateRequiredTarget.classList.remove("text-gray-500", "text-xs")
      this.dateRequiredTarget.classList.add("text-red-500")
    }
    
    // Update help text
    if (this.hasDateHelpTextTarget) {
      this.dateHelpTextTarget.textContent = "The date you typically receive this income (used to calculate how many events per month). Examples: Weekly on Fridays → set to any Friday. Bi-weekly on the 1st and 15th → set to the 1st."
    }
    
    // Change field name from received_on to due_date
    if (this.hasDateInputTarget) {
      const input = this.dateInputTarget
      const value = input.value
      input.name = "due_date"
      input.setAttribute("required", "required")
      input.value = value // Preserve value
    }
  }

  updateDateFieldForOneOff() {
    // Only for income forms
    if (!this.hasDateFieldTarget) {
      return
    }
    
    // Update label
    if (this.hasDateLabelTextTarget) {
      this.dateLabelTextTarget.textContent = "Date"
    }
    
    // Keep required indicator
    if (this.hasDateRequiredTarget) {
      this.dateRequiredTarget.textContent = "*"
      this.dateRequiredTarget.classList.remove("text-gray-500", "text-xs")
      this.dateRequiredTarget.classList.add("text-red-500")
    }
    
    // Update help text
    if (this.hasDateHelpTextTarget) {
      this.dateHelpTextTarget.textContent = "Defaults to today's date"
    }
    
    // Change field name from due_date to received_on
    if (this.hasDateInputTarget) {
      const input = this.dateInputTarget
      const value = input.value
      input.name = "income_event[received_on]"
      input.setAttribute("required", "required")
      input.value = value // Preserve value
    }
  }

  updateDateFieldForExpenseRecurring() {
    // For expense forms, date field stays visible but label/help text may change
    if (!this.hasDateFieldTarget) {
      return
    }
    
    // Update label (stays as "Due Date" for expenses)
    if (this.hasDateLabelTextTarget) {
      this.dateLabelTextTarget.textContent = "Due Date"
    }
    
    // Keep optional indicator
    if (this.hasDateRequiredTarget) {
      this.dateRequiredTarget.textContent = "(optional)"
      this.dateRequiredTarget.classList.remove("text-red-500")
      this.dateRequiredTarget.classList.add("text-gray-500", "text-xs")
    }
    
    // Update help text
    if (this.hasDateHelpTextTarget) {
      this.dateHelpTextTarget.textContent = "Optional: When this expense is typically due"
    }
    
    // Field name stays as "due_date" for expenses
    if (this.hasDateInputTarget) {
      const input = this.dateInputTarget
      input.removeAttribute("required")
    }
  }

  showRecurringFields() {
    this.recurringFieldsTargets.forEach(field => {
      field.classList.remove("hidden")
      // Make frequency and due_date required when recurring is checked
      const inputs = field.querySelectorAll("input[data-recurring-required], select[data-recurring-required]")
      inputs.forEach(input => {
        input.setAttribute("required", "required")
      })
    })
  }

  hideRecurringFields() {
    this.recurringFieldsTargets.forEach(field => {
      field.classList.add("hidden")
      // Remove required when recurring is unchecked
      const inputs = field.querySelectorAll("input[data-recurring-required], select[data-recurring-required]")
      inputs.forEach(input => {
        input.removeAttribute("required")
      })
    })
  }

  showOneOffAmount() {
    if (this.hasOneOffAmountTarget) {
      this.oneOffAmountTargets.forEach(field => {
        field.classList.remove("hidden")
        // Make amount fields required when one-off is shown (for income)
        const amountInput = field.querySelector("input[name*='actual_amount']")
        if (amountInput) {
          amountInput.setAttribute("required", "required")
        }
        // For expenses, allotted_amount is always required (no date field)
        const allottedInput = field.querySelector("input[name*='allotted_amount']")
        if (allottedInput) {
          allottedInput.setAttribute("required", "required")
        }
      })
    }
  }

  hideOneOffAmount() {
    if (this.hasOneOffAmountTarget) {
      this.oneOffAmountTargets.forEach(field => {
        field.classList.add("hidden")
        // Remove required when one-off is hidden
        const amountInput = field.querySelector("input[name*='actual_amount']")
        if (amountInput) {
          amountInput.removeAttribute("required")
        }
        // For expenses, this section doesn't exist, but handle it anyway
        const allottedInput = field.querySelector("input[name*='allotted_amount']")
        if (allottedInput) {
          allottedInput.removeAttribute("required")
        }
      })
    }
  }

  showOneOffDate() {
    if (this.hasOneOffDateTarget) {
      this.oneOffDateTargets.forEach(field => {
        field.classList.remove("hidden")
        // Make date field required when one-off is shown
        const dateInput = field.querySelector("input[name*='received_on']")
        if (dateInput) {
          dateInput.setAttribute("required", "required")
        }
      })
    }
  }

  hideOneOffDate() {
    if (this.hasOneOffDateTarget) {
      this.oneOffDateTargets.forEach(field => {
        field.classList.add("hidden")
        // Remove required when one-off date is hidden
        const dateInput = field.querySelector("input[name*='received_on']")
        if (dateInput) {
          dateInput.removeAttribute("required")
        }
      })
    }
  }
}

