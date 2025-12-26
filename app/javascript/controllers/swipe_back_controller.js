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
    
    // Start swipe from anywhere on the left side of screen (first 50px) - less restrictive
    const touch = event.touches[0]
    if (touch.clientX > 50) {
      this.isSwiping = false
      return
    }
    
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
        const backUrl = new URL(this.backUrlValue, window.location.origin)
        const scrollTo = backUrl.searchParams.get('scroll_to')
        
        // Set up scroll restoration for money map page
        if (scrollTo) {
          const restoreScroll = () => {
            // Wait for page to load and find the scroll container
            const findAndScroll = () => {
              const scrollContainer = document.querySelector('[data-controller*="scroll-to-anchor"]')
              if (scrollContainer) {
                const target = document.getElementById(scrollTo)
                if (target) {
                  // Calculate scroll position
                  const targetRect = target.getBoundingClientRect()
                  const containerRect = scrollContainer.getBoundingClientRect()
                  const scrollTop = scrollContainer.scrollTop + (targetRect.top - containerRect.top) - 20
                  
                  // Scroll to the target
                  scrollContainer.scrollTo({
                    top: Math.max(0, scrollTop),
                    behavior: 'smooth'
                  })
                  
                  // Also ensure the scroll-to-anchor controller processes it
                  // by triggering a custom event or directly scrolling
                  return true
                }
              }
              return false
            }
            
            // Try immediately
            if (findAndScroll()) {
              document.removeEventListener('turbo:load', restoreScroll)
              document.removeEventListener('turbo:render', restoreScroll)
              return
            }
            
            // Try multiple times with increasing delays
            const attempts = [50, 100, 200, 500]
            attempts.forEach((delay, index) => {
              setTimeout(() => {
                if (findAndScroll()) {
                  document.removeEventListener('turbo:load', restoreScroll)
                  document.removeEventListener('turbo:render', restoreScroll)
                }
              }, delay)
            })
            
            // Clean up after all attempts
            setTimeout(() => {
              document.removeEventListener('turbo:load', restoreScroll)
              document.removeEventListener('turbo:render', restoreScroll)
            }, 1000)
          }
          
          // Listen for both turbo:load and turbo:render for better reliability
          document.addEventListener('turbo:load', restoreScroll, { once: true })
          document.addEventListener('turbo:render', restoreScroll, { once: true })
          
          // Also try immediately in case page is already loaded
          setTimeout(restoreScroll, 0)
        }
        
        Turbo.visit(this.backUrlValue)
      } else {
        // Fallback to browser back
        window.history.back()
      }
    }
  }
}

