# Lab: Component & Unit Testing (Vue)

## Objectives

- Write unit tests for pure logic (hooks/composables, utils) with high signal, low brittleness
- Write component tests asserting behavior (what the user sees/does), not implementation details
- Mock API calls at the network boundary instead of mocking internal modules
- Establish a coverage baseline for critical flows (auth, checkout-style CRUD)

## Key Concepts

`Vitest` · `Vue Test Utils` · `MSW (Mock Service Worker)` · `testing behavior not implementation` · `coverage thresholds`

## Tasks

- [ ] Set up Vitest + Vue Test Utils with a jsdom environment
- [ ] Write unit tests for 2 custom composables built in earlier labs (debounce, fetch)
- [ ] Write a component test for the CRUD form asserting validation errors and successful submit behavior
- [ ] Set up MSW to mock the API layer at the network level instead of mocking the axios module directly
- [ ] Write a test for the auth-guarded route redirecting an unauthenticated user
- [ ] Configure a coverage threshold in CI config for the `features/auth` and `features/items` folders

## Expected Output

A test suite covering the auth flow and CRUD form's behavior (not internals), backed by network-level API mocking, with a documented coverage threshold enforced.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
