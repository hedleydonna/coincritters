import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["menu", "button", "moreIcon", "closeIcon", "label"]

  connect() {
    // Close dropdown when clicking outside
    this.boundClickOutside = this.clickOutside.bind(this)
    document.addEventListener("click", this.boundClickOutside)
    
    // Close dropdown after Turbo navigation
    this.boundTurboBeforeVisit = this.close.bind(this)
    document.addEventListener("turbo:before-visit", this.boundTurboBeforeVisit)
    
    // Close dropdown after form submission
    this.boundTurboSubmitEnd = this.close.bind(this)
    document.addEventListener("turbo:submit-end", this.boundTurboSubmitEnd)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
    document.removeEventListener("turbo:before-visit", this.boundTurboBeforeVisit)
    document.removeEventListener("turbo:submit-end", this.boundTurboSubmitEnd)
  }

  toggle() {
    const isOpen = !this.menuTarget.classList.contains("hidden")
    
    if (isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    this.updateButtonState(true)
  }

  close() {
    this.menuTarget.classList.add("hidden")
    this.updateButtonState(false)
  }

  updateButtonState(isOpen) {
    if (this.hasMoreIconTarget && this.hasCloseIconTarget && this.hasLabelTarget) {
      if (isOpen) {
        // Show close icon, hide more icon, change label to "Close"
        this.moreIconTarget.classList.add("hidden")
        this.closeIconTarget.classList.remove("hidden")
        this.labelTarget.textContent = "Close"
      } else {
        // Show more icon, hide close icon, change label to "More"
        this.moreIconTarget.classList.remove("hidden")
        this.closeIconTarget.classList.add("hidden")
        this.labelTarget.textContent = "More"
      }
    }
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}

