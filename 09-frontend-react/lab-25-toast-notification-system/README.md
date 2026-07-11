# Lab: Toast/Notification System (React)

## Objectives

- Build a global toast/notification system triggerable from anywhere (not just component tree state)
- Support success/error/warning/info variants with auto-dismiss and manual dismiss
- Queue and stack multiple toasts without layout jump
- Make toasts screen-reader announced via ARIA live regions

## Key Concepts

`imperative toast API` · `event bus or store-backed toasts` · `ARIA live region` · `auto-dismiss timer` · `stacking/queueing`

## Tasks

- [ ] Build a `toast.success()/error()/info()/warning()` API backed by a global store, not prop-drilled state
- [ ] Render a `<ToastViewport>` mounted once at the app root, subscribed to the store
- [ ] Implement auto-dismiss after N seconds with a pause-on-hover behavior
- [ ] Support manual dismiss and a max-visible-count with overflow queueing
- [ ] Wrap the viewport in an `aria-live="polite"` region for screen reader announcements
- [ ] Trigger toasts from at least 3 different unrelated features (form save, API error interceptor, delete confirm)

## Expected Output

A toast system callable from any module (including non-component code like an API interceptor) that stacks, auto-dismisses, and is screen-reader accessible.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
