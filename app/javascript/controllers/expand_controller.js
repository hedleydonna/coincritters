import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "item"]
  static values = { type: String }
  
  connect() {
    this.expanded = false
    // Store the original button text based on section type
    this.viewAllText = this.typeValue === "income" ? "View All Sources" : "View All Spending"
    // Update date group containers on initial load
    this.updateGroupContainers()
  }
  
  updateGroupContainers() {
    // Show/hide date group containers based on whether they have any visible items
    const groupContainers = this.element.querySelectorAll('[data-expand-group]')
    groupContainers.forEach(container => {
      const itemsInGroup = container.querySelectorAll('[data-expand-target="item"]')
      // Check if any item in this group is visible
      const hasVisibleItems = Array.from(itemsInGroup).some(item => {
        return !item.classList.contains("hidden")
      })
      
      if (hasVisibleItems) {
        container.classList.remove("hidden")
      } else {
        container.classList.add("hidden")
      }
    })
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
    
    // Update date group containers based on visible items
    this.updateGroupContainers()
    
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

