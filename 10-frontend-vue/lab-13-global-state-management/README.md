# Lab: Global State Management (Vue)

## Objectives

- Decide correctly when a piece of state belongs in global store vs local/component state
- Set up a global store with typed actions/selectors and devtools support
- Normalize collection data in the store to avoid duplication and stale copies
- Prevent unnecessary re-renders caused by over-broad store subscriptions

## Key Concepts

`Pinia (defineStore)` · `getters` · `normalized state` · `Vue/Pinia DevTools` · `store subscription granularity`

## Tasks

- [ ] Set up Pinia with one `defineStore` for a `cart` feature
- [ ] Normalize a list of cart items into `{ids, entities}` shape instead of a raw array
- [ ] Write `getters` for derived values (total price, item count)
- [ ] Connect a component with narrow store property access and verify via Vue DevTools it doesn't over-render
- [ ] Add an async action for loading initial cart data from the API
- [ ] Document (README) the rule you used for local vs global state on this feature

## Expected Output

A working cart feature backed by a normalized global store, with DevTools screenshots/notes proving selective subscription avoids full-tree re-renders.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
