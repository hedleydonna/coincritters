import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="payment-delete"
export default class extends Controller {
  static targets = ["form"]
  static values = { paymentAmount: String }

  connect() {
    // Add confirmation handler to delete form
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
    const amount = this.paymentAmountValue || 'this payment'
    const confirmed = confirm(`Are you sure you want to delete this payment of ${amount}?`)
    
    if (!confirmed) {
      event.preventDefault()
      event.stopPropagation()
      return false
    }
  }
}

