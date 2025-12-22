import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    backUrl: String 
  }

  connect() {
    this.startX = 0
    this.startY = 0
    this.startTime = 0
    this.swipeThreshold = 100 // Minimum swipe distance to trigger navigation
    this.maxSwipeTime = 600 // Maximum time for a swipe in milliseconds
    this.isSwiping = false
    
    // Store scroll position before navigating away (for restoring on back navigation)
    this.storeScrollPosition()
  }
  
  storeScrollPosition() {
    // Find the scrollable container (money map page has scroll-to-anchor controller)
    const scrollContainer = document.querySelector('[data-controller*="scroll-to-anchor"]')
    if (scrollContainer) {
      const scrollKey = `scroll_${window.location.pathname}`
      sessionStorage.setItem(scrollKey, scrollContainer.scrollTop.toString())
    }
  }

  touchStart(event) {
    const target = event.target
    const closestLink = target.closest('a[href]')
    const closestButton = target.closest('button, input[type="submit"], input[type="button"]')
    
    // Don't start swipe if touching a clickable link (has href and not just a hash)
    if (closestLink) {
      const href = closestLink.getAttribute('href')
      if (href && href !== '#' && href !== 'javascript:void(0)') {
        this.isSwiping = false
        return
      }
    }
    
    // Don't start swipe if touching a button or submit input
    if (closestButton) {
      this.isSwiping = false
      return
    }
    
    // Don't start swipe on form inputs (text, number, date, textarea, select)
    if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.tagName === 'SELECT') {
      this.isSwiping = false
      return
    }
    
    const touch = event.touches[0]
    this.startX = touch.clientX
    this.startY = touch.clientY
    this.startTime = Date.now()
    this.isSwiping = true
  }

  touchMove(event) {
    if (!this.isSwiping) return
    
    const touch = event.touches[0]
    const currentX = touch.clientX
    const currentY = touch.clientY
    const diffX = currentX - this.startX
    const diffY = Math.abs(currentY - this.startY)
    
    // Only allow rightward swipe (positive diffX) and check if horizontal movement is dominant
    if (diffX > 0 && diffX < 500 && Math.abs(diffX) > diffY * 1.5) {
      // Prevent scrolling during horizontal swipe
      event.preventDefault()
      // Prevent focus on inputs if finger drifts over them
      if (document.activeElement && (document.activeElement.tagName === 'INPUT' || document.activeElement.tagName === 'TEXTAREA')) {
        document.activeElement.blur()
      }
    } else if (diffX < -30 || (diffY > 50 && Math.abs(diffX) < diffY * 1.5)) {
      // If swiping left significantly or vertical movement is dominant, cancel the swipe
      this.isSwiping = false
    }
  }

  touchEnd(event) {
    if (!this.isSwiping) {
      this.isSwiping = false
      return
    }
    
    const touch = event.changedTouches[0]
    const diffX = touch.clientX - this.startX
    const diffY = Math.abs(touch.clientY - this.startY)
    const swipeTime = Date.now() - this.startTime
    
    this.isSwiping = false
    
    // Check if swipe was:
    // 1. Far enough (threshold)
    // 2. Horizontal (more horizontal than vertical)
    // 3. Fast enough (not too slow)
    // 4. Not too long (within time limit)
    const isHorizontal = diffX > diffY * 1.5
    const isFastEnough = swipeTime < this.maxSwipeTime
    const isFarEnough = diffX > this.swipeThreshold
    
    if (isFarEnough && isHorizontal && isFastEnough) {
      // Prevent any click events that might fire
      event.preventDefault()
      event.stopPropagation()
      
      // Store current scroll position before navigating
      this.storeScrollPosition()
      
      // Navigate back using Turbo for better integration
      if (this.hasBackUrlValue) {
        // Use Turbo.visit with action: 'replace' to maintain history
        // and listen for load to restore scroll
        const restoreScroll = () => {
          const scrollContainer = document.querySelector('[data-controller*="scroll-to-anchor"]')
          if (scrollContainer) {
            const scrollKey = `scroll_${new URL(this.backUrlValue).pathname}`
            const savedScroll = sessionStorage.getItem(scrollKey)
            if (savedScroll) {
              // Restore scroll position after a brief delay to ensure content is rendered
              setTimeout(() => {
                scrollContainer.scrollTop = parseInt(savedScroll, 10)
                // Also trigger scroll-to-anchor if there's a scroll_to parameter
                const url = new URL(this.backUrlValue, window.location.origin)
                if (url.searchParams.get('scroll_to')) {
                  // Let scroll-to-anchor controller handle it, but ensure it doesn't override our restore
                  setTimeout(() => {
                    const targetId = url.searchParams.get('scroll_to')
                    const target = document.getElementById(targetId)
                    if (target) {
                      const targetRect = target.getBoundingClientRect()
                      const containerRect = scrollContainer.getBoundingClientRect()
                      const scrollTop = scrollContainer.scrollTop + (targetRect.top - containerRect.top) - 20
                      scrollContainer.scrollTo({
                        top: Math.max(0, scrollTop),
                        behavior: 'smooth'
                      })
                    }
                  }, 100)
                }
              }, 50)
            }
          }
          document.removeEventListener('turbo:load', restoreScroll)
        }
        document.addEventListener('turbo:load', restoreScroll, { once: true })
        
        Turbo.visit(this.backUrlValue)
      } else {
        // Fallback to browser back
        window.history.back()
      }
    }
  }
}

