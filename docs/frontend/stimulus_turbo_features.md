# Stimulus and Turbo Features Documentation

## Overview

This application uses **Stimulus** (a JavaScript framework) and **Turbo** (for fast page navigation) to provide a smooth, app-like experience. This document explains the key frontend features, their implementation, and important concerns.

## Table of Contents

1. [Stimulus Controllers](#stimulus-controllers)
2. [Turbo Integration](#turbo-integration)
3. [Key Features](#key-features)
4. [Implementation Details](#implementation-details)
5. [Concerns and Considerations](#concerns-and-considerations)
6. [Testing](#testing)

---

## Stimulus Controllers

### What is Stimulus?

Stimulus is a modest JavaScript framework that augments HTML with behavior. It connects JavaScript objects (controllers) to DOM elements using data attributes.

### Controller Architecture

All Stimulus controllers are located in `app/javascript/controllers/` and are automatically registered via `stimulus-loading.js`.

### Key Controllers

#### 1. `swipe_back_controller.js`

**Purpose**: Enables swipe-from-left-to-right gesture to navigate back to the previous page.

**Usage**:
```erb
<div data-controller="swipe-back" 
     data-swipe-back-back-url-value="<%= back_path %>"
     data-action="touchstart->swipe-back#touchStart 
                  touchmove->swipe-back#touchMove 
                  touchend->swipe-back#touchEnd">
```

**Features**:
- Detects rightward swipe gestures (left to right)
- Works from anywhere on the page (not just left edge)
- Ignores swipes that start on buttons, links, or form inputs
- Uses Turbo for navigation to maintain app-like feel
- Stores scroll position before navigating

**Configuration**:
- `swipeThreshold`: 100px minimum swipe distance
- `maxSwipeTime`: 600ms maximum swipe duration
- Requires horizontal movement to be 1.5x greater than vertical movement

**Where Used**:
- Income events show page (quick action page)
- Income events edit page
- Any page that needs back navigation

**Concerns**:
- Touch event simulation in tests is complex
- May conflict with native browser swipe gestures
- Requires careful handling to avoid interfering with form interactions

---

#### 2. `scroll_to_anchor_controller.js`

**Purpose**: Automatically scrolls to a specific section on page load, especially after Turbo navigation.

**Usage**:
```erb
<div data-controller="scroll-to-anchor" 
     class="overflow-y-auto">
  <!-- Content with sections like: -->
  <div id="money-in-section">...</div>
</div>
```

**Features**:
- Responds to `scroll_to` query parameter (e.g., `?scroll_to=money-in-section`)
- Works with Turbo navigation events
- Multiple timing strategies for reliable scrolling
- Cleans up URL after scrolling
- Prevents visible "scroll to top then scroll down" jumps

**Configuration**:
- Uses multiple timing strategies:
  1. Immediate (synchronous if DOM ready)
  2. Microtask queue (`Promise.resolve().then()`)
  3. RequestAnimationFrame (next paint)
  4. Minimal setTimeout fallback

**Turbo Events Listened To**:
- `turbo:load` - When page loads
- `turbo:before-render` - Before new content renders
- `turbo:render` - After new content renders

**Where Used**:
- Money Map page (main container)
- Any page that needs scroll-to-section functionality

**Concerns**:
- Timing is critical - must scroll before user sees the jump
- Multiple scroll attempts can cause performance issues (mitigated with flags)
- Requires proper cleanup of event listeners to prevent memory leaks
- May conflict with browser's default scroll restoration

---

#### 3. `dropdown_controller.js`

**Purpose**: Manages the "More" dropdown menu in the bottom navigation.

**Features**:
- Toggles menu visibility
- Closes on outside click
- Closes on Turbo navigation
- Updates button state (More/Close)

**Where Used**:
- Bottom navigation bar

---

#### 4. Other Controllers

- `swipe_controller.js` - Handles swipe-to-mark-received on income events
- `income_view_toggle_controller.js` - Toggles between date/status view for income
- `expense_view_toggle_controller.js` - Toggles between date/status view for expenses
- `recurring_toggle_controller.js` - Shows/hides recurring form fields
- `expand_controller.js` - Expand/collapse functionality
- `select_on_focus_controller.js` - Selects all text when input is focused
- `pull_refresh_controller.js` - Pull-to-refresh functionality

---

## Turbo Integration

### What is Turbo?

Turbo provides fast page navigation without full page reloads. It intercepts link clicks and form submissions, fetches the new page, and swaps content.

### Key Turbo Features Used

1. **Turbo Drive**: Automatic link and form interception
2. **Turbo Frames**: (Not currently used, but available)
3. **Turbo Streams**: (Not currently used, but available)

### Turbo Events

Our controllers listen to these Turbo events:

- `turbo:load` - Fired when a page loads (including Turbo navigations)
- `turbo:before-visit` - Before navigating away
- `turbo:before-render` - Before rendering new content
- `turbo:render` - After rendering new content
- `turbo:submit-end` - After form submission

### Turbo Navigation Patterns

**Standard Link**:
```erb
<%= link_to "Edit", edit_path, data: { turbo: true } %>
```

**Programmatic Navigation**:
```javascript
Turbo.visit(url)  // Navigate to URL
```

**Preventing Turbo**:
```erb
<%= link_to "External", url, data: { turbo: false } %>
```

---

## Key Features

### 1. Swipe-Back Navigation

**User Experience**: Users can swipe right from anywhere on a page to go back, similar to native mobile apps.

**Implementation**:
- Detects touch gestures (touchstart, touchmove, touchend)
- Validates swipe is horizontal and rightward
- Navigates using Turbo for smooth transition
- Stores scroll position for restoration

**Benefits**:
- Familiar mobile gesture
- Works from anywhere on page
- Doesn't interfere with buttons/links/inputs

**Limitations**:
- Only works on touch devices
- Requires sufficient swipe distance (100px)
- May conflict with native browser gestures

---

### 2. Scroll-to-Anchor

**User Experience**: When navigating to a page with `?scroll_to=section-id`, the page automatically scrolls to that section without showing a visible jump.

**Implementation**:
- Listens for `scroll_to` query parameter
- Uses multiple timing strategies to catch earliest moment
- Scrolls within fixed container (not window)
- Cleans up URL after scrolling

**Benefits**:
- Seamless navigation experience
- Works with Turbo navigation
- No visible "flash" of wrong position

**Limitations**:
- Requires target element to exist in DOM
- Timing can be tricky on slow devices
- May need adjustment for very long pages

---

### 3. Mobile-Optimized Interactions

**Features**:
- Touch-friendly button sizes
- Swipe gestures
- Responsive layouts
- Fixed bottom navigation

**Implementation**:
- Tailwind CSS for responsive design
- Stimulus for touch interactions
- Turbo for fast navigation

---

## Implementation Details

### Memory Management

**Critical**: All Stimulus controllers that add event listeners MUST implement `disconnect()` to clean up:

```javascript
connect() {
  this.boundHandler = this.handleEvent.bind(this)
  document.addEventListener('event', this.boundHandler)
}

disconnect() {
  document.removeEventListener('event', this.boundHandler)
}
```

**Why**: Without cleanup, event listeners accumulate on every page navigation, causing memory leaks.

### Event Handler Binding

Always bind event handlers to preserve `this` context:

```javascript
// Good
this.boundHandler = this.handleEvent.bind(this)
document.addEventListener('event', this.boundHandler)

// Bad (can't remove later)
document.addEventListener('event', this.handleEvent.bind(this))
```

### Turbo Event Timing

Turbo events fire in this order:
1. `turbo:before-visit` - Current page, before leaving
2. `turbo:before-render` - New page, before rendering
3. `turbo:render` - New page, after rendering
4. `turbo:load` - New page, fully loaded

**For scrolling**: Use `turbo:render` or `turbo:load` to ensure DOM is ready.

### Scroll Position Management

**Challenge**: Turbo navigates to a new page, which loads at the top, then we need to scroll to a section. This creates a visible jump.

**Solution**: Use multiple timing strategies:
1. Try immediately (if DOM ready)
2. Try in microtask queue
3. Try in requestAnimationFrame
4. Try with minimal setTimeout

**Flag Pattern**: Use a flag to prevent multiple scrolls:
```javascript
if (this.hasScrolled) return
this.scrollToTarget()
this.hasScrolled = true
```

---

## Concerns and Considerations

### 1. Performance

**Multiple Scroll Attempts**: The scroll-to-anchor controller tries multiple times to ensure reliability. This is intentional but could cause performance issues if not guarded.

**Mitigation**: 
- Use flags to prevent duplicate scrolls
- Early return if scroll succeeds
- Limit number of attempts

### 2. Memory Leaks

**Risk**: Event listeners not cleaned up accumulate on every navigation.

**Mitigation**:
- Always implement `disconnect()`
- Store bound handlers for removal
- Test with multiple navigations

### 3. Touch Event Complexity

**Risk**: Touch events are complex and device-specific.

**Mitigation**:
- Test on real devices
- Handle edge cases (multi-touch, etc.)
- Don't interfere with native gestures

### 4. Turbo Navigation Timing

**Risk**: DOM may not be ready when we try to scroll.

**Mitigation**:
- Multiple timing strategies
- Check for element existence
- Use Turbo events appropriately

### 5. Browser Compatibility

**Risk**: Some features may not work in all browsers.

**Mitigation**:
- Test in target browsers
- Use feature detection
- Provide fallbacks

### 6. Accessibility

**Concerns**:
- Swipe gestures may not be discoverable
- Keyboard navigation should still work
- Screen readers need proper announcements

**Mitigation**:
- Provide alternative navigation (buttons/links)
- Ensure keyboard accessibility
- Test with assistive technologies

### 7. Testing Complexity

**Challenge**: Testing touch gestures and Turbo navigation is complex.

**Current Approach**:
- System tests with Capybara/Selenium
- Test that controllers are connected
- Test navigation behavior
- Note: Full touch simulation is difficult

**Future Improvements**:
- Consider Jest/Vitest for unit tests
- Use @testing-library for better simulation
- Add visual regression tests

---

## Testing

### System Tests

System tests are located in `test/system/stimulus_features_test.rb`.

**What's Tested**:
- Scroll-to-anchor functionality
- Swipe-back controller presence
- Turbo navigation behavior
- Form interactions

**Limitations**:
- Touch gestures are difficult to simulate accurately
- Timing-dependent features may need longer waits
- Some tests verify controller presence rather than full functionality

### Manual Testing Checklist

1. **Swipe-Back**:
   - [ ] Swipe right on show page → navigates to money map
   - [ ] Swipe right on edit page → navigates to show page
   - [ ] Swipe doesn't interfere with buttons
   - [ ] Swipe doesn't interfere with form inputs
   - [ ] Swipe doesn't interfere with links

2. **Scroll-to-Anchor**:
   - [ ] Navigate with `?scroll_to=section` → scrolls to section
   - [ ] No visible jump (doesn't show top first)
   - [ ] Works with Turbo navigation
   - [ ] URL is cleaned after scroll
   - [ ] Works on slow devices

3. **Memory Leaks**:
   - [ ] Navigate multiple times → no performance degradation
   - [ ] Check browser memory usage
   - [ ] Verify event listeners are cleaned up

---

## Best Practices

1. **Always implement `disconnect()`** when adding event listeners
2. **Bind event handlers** for proper cleanup
3. **Use flags** to prevent duplicate operations
4. **Test on real devices** for touch interactions
5. **Provide fallbacks** for non-touch devices
6. **Document timing dependencies** in code comments
7. **Keep controllers focused** - one responsibility per controller

---

## Future Enhancements

1. **Unit Tests**: Add Jest/Vitest for controller unit tests
2. **Visual Tests**: Add visual regression testing
3. **Performance Monitoring**: Track scroll timing and success rates
4. **Analytics**: Track swipe gesture usage
5. **Accessibility**: Improve keyboard navigation and screen reader support

---

**Last Updated**: December 2025

