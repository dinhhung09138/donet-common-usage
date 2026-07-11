# Lab: Navigation Menu & Active Link Highlighting (Vue)

## Objectives

- Build a responsive top nav + collapsible sidebar menu with active-route highlighting
- Support nested/collapsible menu groups driven by a config array, not hardcoded JSX
- Implement a mobile hamburger menu with focus-trapped overlay
- Guard menu items by role/permission (visual precursor to full RBAC lab)

## Key Concepts

`router-link-active class` · `RouterLink custom active-class` · `config-driven menu` · `collapsible menu groups` · `mobile drawer` · `focus trap`

## Tasks

- [ ] Build a `menuConfig` array (label, path, icon, children) driving the rendered menu
- [ ] Use `RouterLink` with `active-class` to auto-highlight the active top-level and nested item
- [ ] Implement collapsible menu groups (expand/collapse with `<Transition>`)
- [ ] Build a mobile hamburger menu that opens a focus-trapped overlay drawer
- [ ] Filter menu items by a `requiredRole` field against a mock current-user role
- [ ] Verify keyboard navigation (Tab/Escape) works correctly in the mobile drawer

## Expected Output

A config-driven nav/sidebar with correct active-state highlighting on nested routes, a working mobile drawer, and role-based item filtering.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
