import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "actions"]
  static values = {
    actionUrl: String,
    actionMethod: { type: String, default: "post" }
  }

  connect() {
    this.startX = 0
    this.currentX = 0
    this.swipeThreshold = 50 // Minimum pixels to trigger swipe
    this.isSwiping = false
  }

  touchStart(event) {
    // Only allow swipe if not scrolling
    if (this.element.scrollTop === 0) {
      this.startX = event.touches[0].clientX
      this.isSwiping = true
      if (this.hasContentTarget) {
        this.contentTarget.style.transition = "none"
      }
    }
  }

  touchMove(event) {
    if (!this.isSwiping) return
    
    this.currentX = event.touches[0].clientX
    const diff = this.currentX - this.startX
    
    // Only allow right swipe (positive diff) and limit max distance
    if (diff > 0 && diff < 150) {
      event.preventDefault()
      if (this.hasContentTarget) {
        this.contentTarget.style.transform = `translateX(${diff}px)`
      }
      
      // Show actions when swiped enough
      if (this.hasActionsTarget) {
        if (diff > this.swipeThreshold) {
          this.actionsTarget.classList.remove("hidden")
        } else {
          this.actionsTarget.classList.add("hidden")
        }
      }
    }
  }

  touchEnd(event) {
    if (!this.isSwiping) return
    
    const diff = this.currentX - this.startX
    this.isSwiping = false
    
    if (this.hasContentTarget) {
      this.contentTarget.style.transition = "transform 0.3s ease"
    }
    
    if (diff > this.swipeThreshold) {
      // Swipe completed - keep actions visible
      if (this.hasContentTarget) {
        this.contentTarget.style.transform = `translateX(80px)`
      }
    } else {
      // Swipe not far enough - snap back
      this.reset()
    }
  }

  reset() {
    if (this.hasContentTarget) {
      this.contentTarget.style.transform = "translateX(0)"
    }
    if (this.hasActionsTarget) {
      this.actionsTarget.classList.add("hidden")
    }
  }

  performAction() {
    // Find the form within this element and submit it
    const form = this.element.querySelector("form[data-turbo='true']")
    if (form) {
      form.requestSubmit()
      // Reset swipe after action
      setTimeout(() => this.reset(), 300)
    }
  }
}

