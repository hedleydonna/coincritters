import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    backUrl: String 
  }

  connect() {
    this.startX = 0
    this.startY = 0
    this.startTime = 0
    this.edgeThreshold = 50 // Pixels from left edge to detect edge swipe (increased for easier detection)
    this.swipeThreshold = 80 // Minimum swipe distance to trigger navigation (reduced for easier triggering)
    this.maxSwipeTime = 500 // Maximum time for a swipe in milliseconds
    this.isSwiping = false
    this.startedFromEdge = false
  }

  touchStart(event) {
    const touch = event.touches[0]
    const startX = touch.clientX
    
    // Only start if touch begins near the left edge
    if (startX > this.edgeThreshold) {
      this.isSwiping = false
      this.startedFromEdge = false
      return
    }
    
    // Allow swipe even if touching form elements, as long as it starts from the edge
    // This prevents interference when finger drifts into inputs during swipe
    const target = event.target
    const closestLink = target.closest('a[href]')
    const closestButton = target.closest('button, input[type="submit"], input[type="button"]')
    
    // Don't start swipe if touching a clickable link (has href and not just a hash)
    if (closestLink) {
      const href = closestLink.getAttribute('href')
      if (href && href !== '#' && href !== 'javascript:void(0)') {
        this.isSwiping = false
        this.startedFromEdge = false
        return
      }
    }
    
    // Don't start swipe if touching a button or submit input
    if (closestButton) {
      this.isSwiping = false
      this.startedFromEdge = false
      return
    }
    
    // For other form elements (input, textarea, select), allow swipe if starting from edge
    // This way if finger drifts into an input during swipe, it still works
    
    this.startX = startX
    this.startY = touch.clientY
    this.startTime = Date.now()
    this.isSwiping = true
    this.startedFromEdge = true
    
    // Prevent default scrolling if we're starting a swipe from the edge
    // This helps with responsiveness
    if (startX < 20) {
      event.preventDefault()
    }
  }

  touchMove(event) {
    if (!this.isSwiping || !this.startedFromEdge) return
    
    const touch = event.touches[0]
    const currentX = touch.clientX
    const currentY = touch.clientY
    const diffX = currentX - this.startX
    const diffY = Math.abs(currentY - this.startY)
    
    // Only allow rightward swipe (positive diffX) and check if horizontal movement is dominant
    if (diffX > 0 && diffX < 400 && Math.abs(diffX) > diffY * 1.3) {
      // Prevent scrolling and input focus during swipe
      event.preventDefault()
      // Prevent focus on inputs if finger drifts over them
      if (document.activeElement && document.activeElement.tagName === 'INPUT') {
        document.activeElement.blur()
      }
    } else if (diffX < -20 || (diffY > 0 && Math.abs(diffX) < diffY * 1.3)) {
      // If swiping left significantly or vertical movement is dominant, cancel the swipe
      this.isSwiping = false
    }
  }

  touchEnd(event) {
    if (!this.isSwiping || !this.startedFromEdge) {
      this.isSwiping = false
      this.startedFromEdge = false
      return
    }
    
    const touch = event.changedTouches[0]
    const diffX = touch.clientX - this.startX
    const diffY = Math.abs(touch.clientY - this.startY)
    const swipeTime = Date.now() - this.startTime
    
    this.isSwiping = false
    this.startedFromEdge = false
    
    // Check if swipe was:
    // 1. Far enough (threshold)
    // 2. Horizontal (more horizontal than vertical)
    // 3. Fast enough (not too slow)
    // 4. Not too long (within time limit)
    const isHorizontal = diffX > diffY * 1.3
    const isFastEnough = swipeTime < this.maxSwipeTime
    const isFarEnough = diffX > this.swipeThreshold
    
    if (isFarEnough && isHorizontal && isFastEnough) {
      // Prevent any click events that might fire
      event.preventDefault()
      event.stopPropagation()
      
      // Small delay to ensure any pending events are cleared
      setTimeout(() => {
        // Navigate back
        if (this.hasBackUrlValue) {
          window.location.href = this.backUrlValue
        } else {
          // Fallback to browser back
          window.history.back()
        }
      }, 50)
    }
  }
}

