import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="income-select"
export default class extends Controller {
  static values = { 
    incomes: Object  // Hash of income_id => estimated_amount
  }

  connect() {
    // Store references to form fields
    this.amountField = document.getElementById("income_event_actual_amount")
    this.labelField = document.getElementById("income_event_custom_label")
    this.hintDiv = document.getElementById("estimated-amount-hint")
  }

  updateAmount(event) {
    const incomeId = event.target.value
    const incomes = this.incomesValue || {}
    
    if (incomeId && incomes[incomeId]) {
      const estimatedAmount = parseFloat(incomes[incomeId])
      if (!isNaN(estimatedAmount) && estimatedAmount > 0) {
        // Pre-fill the amount field only if it's empty
        if (this.amountField && (!this.amountField.value || parseFloat(this.amountField.value) === 0)) {
          this.amountField.value = estimatedAmount.toFixed(2)
        }
        // Show hint about estimated amount
        if (this.hintDiv) {
          this.hintDiv.textContent = `Estimated amount: $${estimatedAmount.toFixed(2)} (you can change this)`
          this.hintDiv.classList.remove("hidden")
        }
      }
      // Clear custom label since we're using the income name
      if (this.labelField) {
        this.labelField.value = ""
      }
    } else {
      // Clear hint when no income selected
      if (this.hintDiv) {
        this.hintDiv.classList.add("hidden")
        this.hintDiv.textContent = ""
      }
    }
  }
}

