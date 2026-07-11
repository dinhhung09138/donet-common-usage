# Lab: Debounced Search & Autocomplete (React)

## Objectives

- Implement debounced search input to reduce API call volume
- Build an autocomplete dropdown with keyboard navigation (arrow keys, enter, escape)
- Handle race conditions when responses return out of request order
- Add highlighting of the matched substring in results

## Key Concepts

`debounce` · `race-condition guard (request id/AbortController)` · `keyboard nav` · `ARIA combobox pattern` · `highlight match`

## Tasks

- [ ] Build a search input debounced at 300ms before firing the API call
- [ ] Render a dropdown of results with arrow-key navigation, Enter to select, Escape to close
- [ ] Reproduce a race condition (fast typing returns stale results out of order) and fix it with a request token or AbortController
- [ ] Add `aria-*` attributes implementing the ARIA combobox pattern for accessibility
- [ ] Highlight the matched substring within each result label
- [ ] Add a 'no results' and a loading-indicator-in-dropdown state

## Expected Output

An autocomplete search box that never shows stale out-of-order results and is fully operable by keyboard alone.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
