# Lab: Nested Routes & Layouts (React)

## Objectives

- Structure an app with shared layouts (header/sidebar) via nested routing
- Implement route-level data loading boundaries per layout
- Build breadcrumbs derived from the route tree
- Handle layout-specific loading and error boundaries independently from page content

## Key Concepts

`nested <Route>` · `<Outlet>` · `layout routes` · `index routes` · `breadcrumb derivation` · `route-level error boundary`

## Tasks

- [ ] Create a `DashboardLayout` with a header + sidebar rendering an `<Outlet />`
- [ ] Nest at least 3 child routes under the layout route, including an index route
- [ ] Derive a breadcrumb trail from the current route's matched path segments
- [ ] Add a layout-scoped loading skeleton shown while a child route's data is fetching
- [ ] Add a route-level error boundary so one broken page doesn't crash the whole layout
- [ ] Verify switching between sibling routes does not remount the shared layout

## Expected Output

A dashboard shell whose header/sidebar persist across child route navigation, with working breadcrumbs and an isolated error boundary per section.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
