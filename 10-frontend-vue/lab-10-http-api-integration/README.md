# Lab: HTTP API Integration (Vue)

## Objectives

- Build a typed API client layer decoupled from UI components
- Handle loading, error, and success states consistently across API calls
- Implement request cancellation for in-flight requests on unmount/param change
- Centralize error handling (401/403/5xx) with interceptors

## Key Concepts

`axios instance` · `interceptors` · `AbortController` · `onUnmounted cleanup` · `typed API layer` · `error normalization`

## Tasks

- [ ] Create a shared `axios` instance with a base URL and request/response interceptors
- [ ] Build a typed `api/items.ts` module exposing `getItems`, `getItem`, `createItem`
- [ ] Fetch a list in a component using a composable, handling loading/error/empty states
- [ ] Cancel the in-flight request with `AbortController` on unmount or param change
- [ ] Centralize 401 handling in a response interceptor (redirect to login)
- [ ] Normalize backend error shapes into a single `AppError` type consumed by the UI

## Expected Output

A reusable API layer where every component consumes typed data functions (never raw axios calls), with cancellation and centralized error handling verified via network throttling.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
