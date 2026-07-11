# Lab: Nested Routes & Layouts (Vue)

## Objectives

- Structure an app with shared layouts (header/sidebar) via nested routing
- Implement route-level data loading boundaries per layout
- Build breadcrumbs derived from the route tree
- Handle layout-specific loading and error boundaries independently from page content

## Key Concepts

`nested routes (children)` · `<router-view>` · `named views` · `layout components` · `breadcrumb derivation` · `route-level error handling`

## Tasks

- [ ] Create a `DashboardLayout` with a header + sidebar rendering a `<router-view />`
- [ ] Nest at least 3 child routes under the layout route, including a default child route
- [ ] Derive a breadcrumb trail from `route.matched` path segments
- [ ] Add a layout-scoped loading skeleton shown while a child route's data is fetching
- [ ] Add a route-level error boundary (`onErrorCaptured`) so one broken page doesn't crash the whole layout
- [ ] Verify switching between sibling routes does not remount the shared layout

## Expected Output

A dashboard shell whose header/sidebar persist across child route navigation, with working breadcrumbs and an isolated error boundary per section.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
