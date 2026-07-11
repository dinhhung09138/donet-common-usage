# Lab: Role-Based Access Control & Route Guards (Vue)

## Objectives

- Gate entire routes and individual UI elements by role/permission
- Build a declarative `<Can>`/permission-check pattern reused across the app
- Distinguish 'hidden because unauthorized' from '403 page' UX appropriately
- Keep authorization checks centralized so they can't drift between screens

## Key Concepts

`navigation guard meta.permissions` · `v-if with usePermission composable` · `permission matrix` · `403 page vs conditional hide` · `centralized ability/policy module`

## Tasks

- [ ] Define a central permission matrix mapping roles to allowed actions/routes
- [ ] Build a `usePermission()` composable and a `v-permission` directive for conditional rendering
- [ ] Add route `meta.permissions` checked in a global `router.beforeEach` guard, redirecting to `403`
- [ ] Hide (not just disable) admin-only menu items for non-admin users
- [ ] Write a table (README) of every gated action and its required role for review/audit purposes
- [ ] Add a test that a non-admin user cannot reach an admin route even via direct URL entry

## Expected Output

A role-driven UI where admin-only routes and controls are provably inaccessible (not just visually hidden) to a lower-privilege mock user.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
