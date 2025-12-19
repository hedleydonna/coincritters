import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "actions", "editLink"]

  connect() {
    this.startX = 0
    this.currentX = 0
    this.startY = 0
    this.swipeThreshold = 50
    this.isSwiping = false
    this.swipeOccurred = false
  }

  touchStart(event) {
    // Don't start swipe if touching a button
    if (event.target.closest('button')) {
      return
    }
    
    this.startX = event.touches[0].clientX
    this.startY = event.touches[0].clientY
    this.isSwiping = true
    this.swipeOccurred = false
    
    if (this.hasContentTarget) {
      this.contentTarget.style.transition = "none"
      this.contentTarget.style.willChange = "transform"
    }
  }

  touchMove(event) {
    if (!this.isSwiping) return
    
    this.currentX = event.touches[0].clientX
    const currentY = event.touches[0].clientY
    const diffX = this.currentX - this.startX
    const diffY = Math.abs(currentY - this.startY)
    
    // Only allow right swipe (positive diffX) and check if horizontal movement is dominant
    if (diffX > 0 && diffX < 200 && Math.abs(diffX) > diffY) {
      // Prevent scrolling and link clicks during swipe
      event.preventDefault()
      event.stopPropagation()
      
      if (this.hasContentTarget) {
        this.contentTarget.style.transform = `translateX(${Math.min(diffX, 80)}px)`
      }
      
      // Show/hide actions based on swipe distance
      if (this.hasActionsTarget) {
        if (diffX > this.swipeThreshold) {
          this.actionsTarget.classList.remove("hidden")
          this.swipeOccurred = true
        } else {
          this.actionsTarget.classList.add("hidden")
          this.swipeOccurred = false
        }
      }
    }
  }

  touchEnd(event) {
    if (!this.isSwiping) return
    
    const diff = this.currentX - this.startX
    const diffY = Math.abs(event.changedTouches[0].clientY - this.startY)
    this.isSwiping = false
    
    if (this.hasContentTarget) {
      this.contentTarget.style.transition = "transform 0.3s ease"
      this.contentTarget.style.willChange = "auto"
    }
    
    // Check if swipe was far enough and horizontal
    if (diff > this.swipeThreshold && diff > diffY) {
      // Swipe completed - keep actions visible
      if (this.hasContentTarget) {
        this.contentTarget.style.transform = `translateX(80px)`
      }
      this.swipeOccurred = true
      
      // Prevent link navigation for a short time after swipe
      if (this.hasEditLinkTarget) {
        const preventClick = (e) => {
          e.preventDefault()
          e.stopPropagation()
          e.stopImmediatePropagation()
        }
        this.editLinkTarget.addEventListener("click", preventClick, { once: true, capture: true })
        setTimeout(() => {
          this.swipeOccurred = false
        }, 500)
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
    this.swipeOccurred = false
  }

  handleButtonClick(event) {
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()
    
    const form = this.element.querySelector("form[data-turbo='true']")
    if (form) {
      form.requestSubmit()
      this.reset()
    }
  }
}
