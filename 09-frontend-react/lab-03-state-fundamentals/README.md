# Lab: Local State Fundamentals (React)

## Objectives

- Model UI state correctly (derived vs source-of-truth) to avoid redundant state bugs
- Understand the framework's reactivity/render model well enough to explain unnecessary re-renders
- Lift state up only as far as needed and colocate state with the component that owns it
- Build a stateful counter/toggle/tab-switcher set that demonstrates each pattern

## Key Concepts

`useState` · `derived state` · `state colocation` · `lifting state up` · `re-render triggers` · `reconciliation basics`

## Tasks

- [ ] Build a counter, a toggle, and a tab-switcher each using local `useState`
- [ ] Refactor a component that stores a derived value in state into a computed value instead
- [ ] Demonstrate state colocation: move state down from a parent into the child that actually uses it
- [ ] Demonstrate lifting state up: two sibling components need to share one piece of state
- [ ] Use React DevTools profiler to show which state change triggers which re-render
- [ ] Write a short note (README) on when to use state vs derive from props

## Expected Output

Working counter/toggle/tabs demo with no redundant state (nothing stored that could be derived) and a written rationale for each state placement decision.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
