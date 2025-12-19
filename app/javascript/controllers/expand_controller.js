import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "item"]
  static values = { type: String }
  
  connect() {
    this.expanded = false
    // Store the original button text based on section type
    this.viewAllText = this.typeValue === "income" ? "View All Sources" : "View All Spending"
  }

  toggle() {
    this.expanded = !this.expanded
    
    // Show/hide items beyond the first 5
    this.itemTargets.forEach((item, index) => {
      if (index >= 5) {
        if (this.expanded) {
          item.classList.remove("hidden")
        } else {
          item.classList.add("hidden")
        }
      }
    })
    
    // Update button text
    if (this.hasToggleTarget) {
      if (this.expanded) {
        this.toggleTarget.textContent = "Collapse"
      } else {
        this.toggleTarget.textContent = this.viewAllText
      }
    }
  }
}

