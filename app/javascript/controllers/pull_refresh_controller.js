import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["indicator"]
  
  connect() {
    this.startY = 0
    this.pulling = false
    this.pullDistance = 0
  }

  touchStart(event) {
    // Only allow pull if at top of page
    if (window.scrollY === 0) {
      this.startY = event.touches[0].clientY
    }
  }

  touchMove(event) {
    if (window.scrollY === 0 && this.startY > 0) {
      const currentY = event.touches[0].clientY
      this.pullDistance = currentY - this.startY
      
      if (this.pullDistance > 0) {
        event.preventDefault()
        this.pulling = true
        
        // Show pull indicator
        if (this.hasIndicatorTarget) {
          this.indicatorTarget.classList.remove("hidden")
          const opacity = Math.min(this.pullDistance / 100, 1)
          this.indicatorTarget.style.opacity = opacity
          
          if (this.pullDistance > 80) {
            this.indicatorTarget.textContent = "Release to refresh"
            this.indicatorTarget.classList.add("bg-green-600")
            this.indicatorTarget.classList.remove("bg-blue-600")
          } else {
            this.indicatorTarget.textContent = "Pull to refresh"
            this.indicatorTarget.classList.add("bg-blue-600")
            this.indicatorTarget.classList.remove("bg-green-600")
          }
        }
      }
    }
  }

  touchEnd(event) {
    if (this.pulling && this.pullDistance > 80) {
      // Trigger refresh using Turbo
      this.refresh()
    } else {
      // Reset
      this.reset()
    }
    
    this.startY = 0
    this.pulling = false
    this.pullDistance = 0
  }

  refresh() {
    if (this.hasIndicatorTarget) {
      this.indicatorTarget.textContent = "Refreshing..."
      this.indicatorTarget.classList.add("bg-green-600")
      this.indicatorTarget.classList.remove("bg-blue-600")
    }
    
    // Use Turbo to refresh the page
    Turbo.visit(window.location.href, { action: "replace" })
    
    // Reset after a delay
    setTimeout(() => this.reset(), 1000)
  }

  reset() {
    if (this.hasIndicatorTarget) {
      this.indicatorTarget.classList.add("hidden")
      this.indicatorTarget.style.opacity = "0"
    }
  }
}

