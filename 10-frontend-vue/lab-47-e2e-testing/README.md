# Lab: End-to-End Testing (Vue)

## Objectives

- Automate a full critical user journey through a real browser
- Stub network responses at the E2E layer for deterministic, fast tests
- Run E2E tests in CI against a built (not dev-server) artifact
- Capture screenshots/video/trace on failure for debuggability

## Key Concepts

`Playwright` · `page object pattern` · `network route interception` · `CI headless run` · `trace viewer on failure`

## Tasks

- [ ] Set up Playwright and write a page-object model for the login and CRUD-list screens
- [ ] Automate the full journey: login → create item → edit item → delete item → verify list state
- [ ] Intercept and stub the relevant API routes for deterministic test data, independent of a real backend
- [ ] Add a test asserting the RBAC-guarded route redirects for a non-admin test user
- [ ] Configure the test run against a production build (`vite preview`) rather than the dev server
- [ ] Enable trace/screenshot/video capture on failure and verify it produces a usable artifact

## Expected Output

A Playwright suite that runs headless against a production build in CI, covering login-to-delete CRUD journey and one RBAC redirect case, with failure traces enabled.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
