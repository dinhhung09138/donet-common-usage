# Lab: Conditional Rendering & Dynamic Styling (React)

## Objectives

- Apply conditional rendering patterns without producing unreadable nested ternaries
- Toggle classes/styles dynamically based on state (active, disabled, error variants)
- Build a status-badge/alert component with variant-driven styling
- Avoid common falsy-value rendering bugs (0, empty string, empty array)

## Key Concepts

`&&, ternary, early return` · `classnames/clsx` · `CSS Modules or Tailwind variants` · `falsy rendering pitfalls` · `component variants`

## Tasks

- [ ] Build an `Alert` component with `success/warning/error/info` variants driving color and icon
- [ ] Use `clsx`/`classnames` to compose conditional class lists instead of string concatenation
- [ ] Refactor a deeply nested ternary into an early-return or a lookup-table pattern
- [ ] Reproduce and fix a falsy-render bug (e.g. `{count && <Badge/>}` rendering `0`)
- [ ] Toggle a loading/disabled state on a button with both class and `aria-disabled` changes
- [ ] Compare `display:none` toggling vs unmount/remount for an expensive child component

## Expected Output

An Alert/status component demo covering all variants, with a documented before/after of one fixed conditional-rendering bug.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
