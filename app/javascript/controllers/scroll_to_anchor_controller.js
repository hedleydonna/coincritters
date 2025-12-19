import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scrollToTarget()
    // Also listen for Turbo navigation events
    document.addEventListener('turbo:load', () => {
      this.scrollToTarget()
    })
  }

  scrollToTarget() {
    // Check for scroll_to query parameter or hash
    const urlParams = new URLSearchParams(window.location.search)
    const scrollTo = urlParams.get('scroll_to')
    const hash = window.location.hash.replace('#', '')
    const targetId = scrollTo || hash
    
    if (targetId) {
      // Wait for Turbo to finish rendering - increased timeout for reliability
      setTimeout(() => {
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
        }
      }, 500)
    }
  }
}

