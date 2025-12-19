import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Select all text when field receives focus
    this.element.addEventListener("focus", this.selectAll.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("focus", this.selectAll.bind(this))
  }

  selectAll(event) {
    // Small delay to ensure the field is fully focused
    setTimeout(() => {
      if (this.element.value === "0" || this.element.value === "0.00" || this.element.value === "") {
        // If value is 0 or empty, select all so typing replaces it
        this.element.select()
      } else {
        // For other values, also select all for easy replacement
        this.element.select()
      }
    }, 10)
  }
}

