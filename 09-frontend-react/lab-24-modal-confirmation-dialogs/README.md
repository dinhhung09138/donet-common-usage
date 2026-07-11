# Lab: Modal & Confirmation Dialogs (React)

## Objectives

- Build an accessible modal (focus trap, Escape to close, backdrop click) from scratch or headless primitives
- Implement a reusable imperative confirmation dialog ('Are you sure?') usable from anywhere in the app
- Support stacked/nested modals correctly
- Prevent background scroll and restore focus to the trigger element on close

## Key Concepts

`React Portal` · `focus trap` · `imperative confirm() promise pattern` · `aria-modal` · `scroll lock`

## Tasks

- [ ] Build a `Modal` component rendered via `createPortal` with `aria-modal`, focus trap, and Escape-to-close
- [ ] Build a `confirm(options): Promise<boolean>` utility callable from any event handler without JSX boilerplate
- [ ] Use the confirm utility to gate a destructive delete action
- [ ] Support two modals stacked at once (e.g. confirm-delete opened from within an edit modal)
- [ ] Lock body scroll while any modal is open and unlock only when the last one closes
- [ ] Verify focus returns to the exact element that opened the modal after it closes

## Expected Output

A reusable, accessible modal system with a promise-based confirm() helper wired into a real delete action, verified against stacked-modal and focus-return edge cases.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
