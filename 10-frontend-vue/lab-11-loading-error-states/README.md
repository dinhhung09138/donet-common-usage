# Lab: Loading, Error & Empty States (Vue)

## Objectives

- Design a consistent UX pattern for loading/error/empty across the app (not ad hoc per screen)
- Build skeleton loaders instead of spinners for perceived performance
- Implement retry-on-error UX with exponential backoff for transient failures
- Distinguish empty-because-no-data from empty-because-filtered

## Key Concepts

`skeleton components` · `async state machine (idle/loading/success/error)` · `retry with backoff` · `empty-state component`

## Tasks

- [ ] Define a shared `AsyncState<T>` type (`idle|loading|success|error`) used by every composable
- [ ] Build a `Skeleton` component and use it in place of a spinner on at least 2 screens
- [ ] Implement retry with exponential backoff for a simulated flaky endpoint
- [ ] Build a generic `EmptyState` component with distinct copy for 'no data' vs 'no results for this filter'
- [ ] Wire a global toast for unrecoverable errors and inline messaging for recoverable ones
- [ ] Write a matrix (README table) mapping each async state to its exact UI treatment

## Expected Output

Two or more screens sharing the same async-state UI vocabulary, with retry-with-backoff demonstrably working against a simulated flaky endpoint.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
