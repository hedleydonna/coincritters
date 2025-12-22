import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.urlCleaned = false
    this.hasScrolled = false
    this.pendingScrollTo = null
    
    // Check if we're returning to this page with a scroll_to parameter
    const urlParams = new URLSearchParams(window.location.search)
    const scrollTo = urlParams.get('scroll_to')
    
    if (scrollTo) {
      // Try scrolling immediately with multiple strategies
      this.attemptImmediateScroll(scrollTo)
    } else {
      this.scrollToTarget()
    }
    
    // Bind event handlers for proper cleanup
    this.boundTurboLoad = this.handleTurboLoad.bind(this)
    this.boundTurboBeforeRender = this.handleTurboBeforeRender.bind(this)
    this.boundTurboRender = this.handleTurboRender.bind(this)
    
    // Listen for Turbo navigation events
    document.addEventListener('turbo:load', this.boundTurboLoad)
    document.addEventListener('turbo:before-render', this.boundTurboBeforeRender)
    document.addEventListener('turbo:render', this.boundTurboRender)
  }
  
  disconnect() {
    // Clean up event listeners to prevent memory leaks
    document.removeEventListener('turbo:load', this.boundTurboLoad)
    document.removeEventListener('turbo:before-render', this.boundTurboBeforeRender)
    document.removeEventListener('turbo:render', this.boundTurboRender)
  }
  
  handleTurboLoad() {
    const urlParams = new URLSearchParams(window.location.search)
    const scrollTo = urlParams.get('scroll_to')
    if (scrollTo) {
      this.hasScrolled = false // Reset flag for new navigation
      this.attemptImmediateScroll(scrollTo)
    } else {
      this.scrollToTarget()
    }
  }
  
  handleTurboBeforeRender(event) {
    const url = new URL(event.detail.url, window.location.origin)
    const scrollTo = url.searchParams.get('scroll_to')
    if (scrollTo) {
      // Store the target ID to scroll to after render
      this.pendingScrollTo = scrollTo
      this.hasScrolled = false // Reset flag
    }
  }
  
  handleTurboRender() {
    if (this.pendingScrollTo && !this.hasScrolled) {
      // Try to scroll immediately after render - multiple attempts
      this.attemptImmediateScroll(this.pendingScrollTo)
      // Fallback with minimal delay
      setTimeout(() => {
        if (!this.hasScrolled) {
          this.attemptImmediateScroll(this.pendingScrollTo)
        }
      }, 0)
      this.pendingScrollTo = null
    }
  }
  
  attemptImmediateScroll(targetId) {
    // Guard against multiple scrolls
    if (this.hasScrolled) return
    
    // Try multiple times with different timing strategies
    // 1. Immediate (synchronous if DOM ready)
    if (this.scrollToTargetImmediate(targetId)) {
      this.hasScrolled = true
      return
    }
    
    // 2. Microtask (next tick)
    Promise.resolve().then(() => {
      if (this.hasScrolled) return
      if (this.scrollToTargetImmediate(targetId)) {
        this.hasScrolled = true
        return
      }
      
      // 3. RequestAnimationFrame (next paint)
      requestAnimationFrame(() => {
        if (this.hasScrolled) return
        if (this.scrollToTargetImmediate(targetId)) {
          this.hasScrolled = true
          return
        }
        
        // 4. Minimal setTimeout fallback
        setTimeout(() => {
          if (!this.hasScrolled) {
            this.scrollToTargetImmediate(targetId)
            this.hasScrolled = true
          }
        }, 0)
      })
    })
  }
  
  scrollToTargetImmediate(targetId) {
    const target = document.getElementById(targetId)
    if (target && this.element) {
      const scrollContainer = this.element
      const targetRect = target.getBoundingClientRect()
      const containerRect = scrollContainer.getBoundingClientRect()
      const scrollTop = scrollContainer.scrollTop + (targetRect.top - containerRect.top) - 20
      
      // Scroll instantly (no smooth behavior) to prevent visible jump
      // Use scrollTop directly for instant scroll
      scrollContainer.scrollTop = Math.max(0, scrollTop)
      
      // Clean up URL (only once, use a flag to prevent multiple cleanups)
      if (!this.urlCleaned) {
        const urlParams = new URLSearchParams(window.location.search)
        const scrollTo = urlParams.get('scroll_to')
        if (scrollTo) {
          const newUrl = window.location.pathname + window.location.search.replace(/[?&]scroll_to=[^&]*/, '').replace(/^&/, '?')
          window.history.replaceState({}, '', newUrl)
          this.urlCleaned = true
        }
      }
      
      return true
    }
    return false
  }

  scrollToTarget() {
    // Check for scroll_to query parameter or hash
    const urlParams = new URLSearchParams(window.location.search)
    const scrollTo = urlParams.get('scroll_to')
    const hash = window.location.hash.replace('#', '')
    const targetId = scrollTo || hash
    
    if (targetId) {
      // Try to scroll immediately (for Turbo navigations where content is already loaded)
      if (this.attemptScroll(targetId, scrollTo)) {
        return // Successfully scrolled
      }
      
      // If target not found yet, wait a bit for content to render
      setTimeout(() => {
        this.attemptScroll(targetId, scrollTo)
      }, 50)
      
      // Fallback for slower renders
      setTimeout(() => {
        this.attemptScroll(targetId, scrollTo)
      }, 200)
    }
  }
  
  attemptScroll(targetId, scrollTo) {
    const target = document.getElementById(targetId)
    if (target) {
      // The scrollable container is this.element itself (it has overflow-y-auto)
      const scrollContainer = this.element
      
      // Calculate the target's position relative to the container
      const targetRect = target.getBoundingClientRect()
      const containerRect = scrollContainer.getBoundingClientRect()
      
      // Calculate scroll position: current scroll + (target top - container top) - offset
      const scrollTop = scrollContainer.scrollTop + (targetRect.top - containerRect.top) - 20
      
      scrollContainer.scrollTo({
        top: Math.max(0, scrollTop),
        behavior: 'smooth'
      })
      
      // Clean up URL by removing query parameter
      if (scrollTo) {
        const newUrl = window.location.pathname + window.location.search.replace(/[?&]scroll_to=[^&]*/, '').replace(/^&/, '?')
        window.history.replaceState({}, '', newUrl)
      }
      
      return true // Successfully scrolled
    }
    return false // Target not found yet
  }
}

