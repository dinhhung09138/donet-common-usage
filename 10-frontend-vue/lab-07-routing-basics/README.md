# Lab: Client-Side Routing Basics (Vue)

## Objectives

- Set up client-side routing with static and dynamic (param-based) routes
- Read and write route params and query strings
- Implement programmatic navigation and a working browser back/forward experience
- Build a 404 / catch-all route

## Key Concepts

`vue-router` · `createRouter` · `route params ($route.params)` · `useRoute/useRouter` · `router.push` · `catch-all route`

## Tasks

- [ ] Install `vue-router` and configure a router with at least 4 routes
- [ ] Add a dynamic route `/items/:id` and read the param via `useRoute().params`
- [ ] Add query-string state (e.g. `?sort=asc`) read/written via `useRoute().query` / `router.push`
- [ ] Implement programmatic navigation (`router.push`) after a form submit
- [ ] Verify browser back/forward correctly restores scroll position and route state
- [ ] Add a catch-all `:pathMatch(.*)*` route rendering a 404 page

## Expected Output

A multi-page app where direct URL entry, param routes, query strings, and back/forward navigation all behave correctly, including a 404 for unknown paths.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
