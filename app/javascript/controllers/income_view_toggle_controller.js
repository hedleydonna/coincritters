import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dateView", "statusView", "toggleText"]

  connect() {
    // Only initialize if targets exist (i.e., there are income events)
    if (this.hasDateViewTarget && this.hasStatusViewTarget) {
      // Default to date view
      this.showDateView()
    }
  }

  toggle(event) {
    event.preventDefault()
    // Only toggle if targets exist
    if (!this.hasDateViewTarget || !this.hasStatusViewTarget) {
      return
    }
    
    if (this.dateViewTarget.classList.contains("hidden")) {
      this.showDateView()
    } else {
      this.showStatusView()
    }
  }

  showDateView() {
    if (!this.hasDateViewTarget || !this.hasStatusViewTarget) {
      return
    }
    
    this.dateViewTarget.classList.remove("hidden")
    this.statusViewTarget.classList.add("hidden")
    if (this.hasToggleTextTarget) {
      this.toggleTextTarget.textContent = "Group by Status"
    }
  }

  showStatusView() {
    if (!this.hasDateViewTarget || !this.hasStatusViewTarget) {
      return
    }
    
    this.dateViewTarget.classList.add("hidden")
    this.statusViewTarget.classList.remove("hidden")
    if (this.hasToggleTextTarget) {
      this.toggleTextTarget.textContent = "Group by Date"
    }
  }
}

