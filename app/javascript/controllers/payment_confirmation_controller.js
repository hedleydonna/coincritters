import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="payment-confirmation"
export default class extends Controller {
  static targets = ["amount", "form"]

  connect() {
    // Auto-focus on amount field
    if (this.hasAmountTarget) {
      this.amountTarget.focus()
      // Select the value if it's pre-filled
      if (this.amountTarget.value) {
        this.amountTarget.select()
      }
    }

    // Add confirmation handler
    if (this.hasFormTarget) {
      this.formTarget.addEventListener("submit", this.handleSubmit.bind(this))
    }
  }

  disconnect() {
    // Clean up event listener when controller disconnects
    if (this.hasFormTarget) {
      this.formTarget.removeEventListener("submit", this.handleSubmit.bind(this))
    }
  }

  handleSubmit(event) {
    const amount = parseFloat(this.amountTarget.value) || 0
    
    if (amount > 0) {
      const formattedAmount = new Intl.NumberFormat('en-US', { 
        style: 'currency', 
        currency: 'USD' 
      }).format(amount)
      
      const confirmed = confirm(`Add payment of ${formattedAmount}?`)
      if (!confirmed) {
        event.preventDefault()
        event.stopPropagation()
        return false
      }
    } else {
      // If amount is 0 or invalid, prevent submission
      event.preventDefault()
      alert('Please enter a valid payment amount.')
      if (this.hasAmountTarget) {
        this.amountTarget.focus()
        this.amountTarget.select()
      }
      return false
    }
  }
}

