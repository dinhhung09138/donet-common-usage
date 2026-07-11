# Lab: List Rendering & Keys (React)

## Objectives

- Render dynamic lists correctly using stable keys, not array index
- Diagnose and fix a rendering bug caused by incorrect keying during reorder/delete
- Implement empty-list and single-item edge cases explicitly
- Build a filterable list where item identity is preserved across re-renders

## Key Concepts

`key prop` · `reconciliation with keys` · `array index anti-pattern` · `memoized list items` · `empty state` · `stable identity`

## Tasks

- [ ] Render a list of items with `.map()` using a stable unique `key`
- [ ] Reproduce a visible bug by keying on array index during item deletion/reorder, then fix it
- [ ] Add delete and reorder (move up/down) actions and verify item identity (e.g. input focus) survives
- [ ] Implement an explicit empty-state and a single-item edge case
- [ ] Wrap list items in `React.memo` and prove (via console logs) that unrelated updates don't re-render every item
- [ ] Add a client-side filter/search box that narrows the rendered list

## Expected Output

A list UI where delete/reorder never mixes up item state, backed by a documented before/after fix of the index-key bug.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
