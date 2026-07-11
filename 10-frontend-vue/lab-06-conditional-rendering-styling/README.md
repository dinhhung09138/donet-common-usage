# Lab: Conditional Rendering & Dynamic Styling (Vue)

## Objectives

- Apply conditional rendering patterns without producing unreadable nested ternaries
- Toggle classes/styles dynamically based on state (active, disabled, error variants)
- Build a status-badge/alert component with variant-driven styling
- Avoid common falsy-value rendering bugs (0, empty string, empty array)

## Key Concepts

`v-if/v-else-if/v-else` · `v-show vs v-if` · `:class object/array binding` · `CSS Modules or Tailwind variants` · `falsy rendering pitfalls`

## Tasks

- [ ] Build an `Alert` component with `success/warning/error/info` variants driving color and icon
- [ ] Use `:class` object syntax to compose conditional class lists instead of string concatenation
- [ ] Refactor a deeply nested `v-if`/`v-else-if` chain into a computed lookup-table pattern
- [ ] Reproduce and fix a falsy-render bug in an interpolation (e.g. `{{ count }}` showing `0` unexpectedly hidden)
- [ ] Toggle a loading/disabled state on a button with both class and `aria-disabled` changes
- [ ] Compare `v-show` vs `v-if` for an expensive child component and measure the difference

## Expected Output

An Alert/status component demo covering all variants, with a documented before/after of one fixed conditional-rendering bug.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
