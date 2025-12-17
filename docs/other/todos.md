# Todos

## Fixed: One-off expense form

**Problem**: The "Add One-Off Expense" form included a template dropdown, which shouldn't be needed for one-off expenses.

**Solution**:
- Removed the template dropdown from the new expense form
- Simplified the form to only show:
  - Expense Name (required)
  - Amount (required)
- Updated the controller to remove unnecessary `@expense_templates` loading
- Updated documentation to reflect that this form is specifically for one-off expenses

**Note**: The edit form still includes the template dropdown, which is fine for editing existing expenses (allows linking/unlinking from templates).

## Priority recommendations

1. Mobile-first polish (High Priority)
   - Swipe actions for common tasks
   - Pull-to-refresh functionality
   - Form tweaking (minor improvements you mentioned)

2. Month-end summary (Medium Priority)
   - "How Did I Do?" summary page
   - Month-over-month comparisons
   - Visual insights

3. Undo functionality (Medium Priority)
   - Quick reverse for accidental actions
   - Reduces user anxiety

4. Empty states (Medium Priority)
   - Helpful guidance when no data exists

5. Loading states (Medium Priority)
   - Progress indicators during operations

Recommendation: Start with mobile-first polish (swipe actions and pull-to-refresh) since mobile testing is complete and the app is functional. These will improve the mobile experience.





Checking where the viewport meta tag is configured:


[1 tool called]


The viewport meta tag is on line 5 of your layout file.

## What is the Viewport Meta Tag?

The viewport meta tag tells mobile browsers how to render your page. Without it, mobile browsers may render the page at desktop width and then shrink it, making text tiny and requiring zooming.

## Where You Have It

In `app/views/layouts/application.html.erb` on line 5:

```html
<meta name="viewport" content="width=device-width,initial-scale=1">
```

## What It Does

- `width=device-width` — Sets the page width to match the device’s screen width
- `initial-scale=1` — Sets the initial zoom level to 100% (no zoom)

## Why It Matters

Without it:
- Mobile browsers assume a desktop width (often 980px)
- Text appears tiny
- Users must zoom to read
- Responsive design may not work correctly

With it:
- Page renders at the device’s actual width
- Text is readable
- Responsive CSS (like Tailwind’s `sm:`, `md:`) works correctly
- Better mobile experience

## How You Got It

Rails likely added it when generating the layout, or it was added manually. It’s a standard best practice for mobile-friendly sites.

## Bottom Line

You already have it configured correctly. This is why your app works on mobile devices. Without it, even with responsive CSS, mobile browsers would render the page incorrectly.

This is one of the items already in place that makes your app ready for mobile testing.