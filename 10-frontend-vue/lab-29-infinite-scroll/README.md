# Lab: Infinite Scroll & Lazy Data Loading (Vue)

## Objectives

- Implement infinite scroll using IntersectionObserver instead of scroll-event polling
- Combine infinite scroll with virtualization for very large lists
- Prevent duplicate page fetches from rapid scroll events
- Preserve scroll position when navigating away and back

## Key Concepts

`IntersectionObserver` · `sentinel element` · `fetch de-duplication` · `scroll position restoration` · `virtualized infinite list`

## Tasks

- [ ] Build a feed that loads the next page when a sentinel element intersects the viewport
- [ ] Guard against firing duplicate fetches while a page is already loading
- [ ] Combine with row virtualization so 1000+ loaded items don't degrade scroll performance
- [ ] Cache loaded pages in memory so navigating away and back doesn't re-fetch from page 1
- [ ] Restore exact scroll offset when returning to the feed via back navigation
- [ ] Add a manual 'Load more' fallback button for environments without IntersectionObserver

## Expected Output

An infinite-scrolling feed of 1000+ items that stays smooth (virtualized), never double-fetches, and restores scroll position after back navigation.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
