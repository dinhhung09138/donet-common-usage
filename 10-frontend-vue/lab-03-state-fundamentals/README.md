# Lab: Local State Fundamentals (Vue)

## Objectives

- Model UI state correctly (derived vs source-of-truth) to avoid redundant state bugs
- Understand the framework's reactivity/render model well enough to explain unnecessary re-renders
- Lift state up only as far as needed and colocate state with the component that owns it
- Build a stateful counter/toggle/tab-switcher set that demonstrates each pattern

## Key Concepts

`ref vs reactive` · `computed (derived state)` · `state colocation` · `lifting state up` · `reactivity triggers` · `template re-render basics`

## Tasks

- [ ] Build a counter, a toggle, and a tab-switcher each using `ref`
- [ ] Refactor a component that stores a derived value in `ref` into a `computed` instead
- [ ] Demonstrate state colocation: move `ref` down from a parent into the child that actually uses it
- [ ] Demonstrate lifting state up: two sibling components need to share one piece of state via the parent
- [ ] Use Vue DevTools to inspect reactivity dependency tracking on a `computed`
- [ ] Write a short note (README) on when to use `ref`/`reactive` vs `computed`

## Expected Output

Working counter/toggle/tabs demo with no redundant state (nothing stored that could be derived) and a written rationale for each state placement decision.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
