# Lab: Error Boundary & Global Error Handling (Vue)

## Objectives

- Contain component-tree crashes with error boundaries instead of blanking the whole app
- Centralize unhandled promise rejection and global error capture for logging
- Report errors to a monitoring service with useful context (route, user, breadcrumbs)
- Design a user-facing fallback UI distinct from a developer-facing error detail view

## Key Concepts

`app.config.errorHandler` · `onErrorCaptured` · `window.onerror/unhandledrejection` · `error reporting context (breadcrumbs)` · `fallback UI per boundary granularity`

## Tasks

- [ ] Configure `app.config.errorHandler` for global uncaught error capture
- [ ] Add `onErrorCaptured` boundaries around each major route/section so one crash doesn't blank the whole app
- [ ] Hook `window.onerror` and `unhandledrejection` to capture errors outside the Vue component tree
- [ ] Attach breadcrumb context (last 5 route changes, last action) to every reported error
- [ ] Send captured errors to a mock reporting endpoint with route, user id, and stack trace
- [ ] Build distinct fallback UIs: a friendly user-facing message vs a dev-only stack trace panel (env-gated)

## Expected Output

A deliberately-thrown error in one section is contained by its boundary (rest of the app stays usable) and is reported to a mock endpoint with full breadcrumb context.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
