# Lab: CRUD Form: Create & Edit (Vue)

## Objectives

- Build a single reusable form component serving both create and edit flows
- Pre-populate edit forms from fetched data with correct loading/error handling
- Implement optimistic UI update on save with rollback on failure
- Prevent accidental data loss when navigating away from a dirty form

## Key Concepts

`shared create/edit form component` · `optimistic update` · `dirty-state guard (onBeforeRouteLeave)` · `form reset on entity change`

## Tasks

- [ ] Build one `ItemForm` component used by both `/items/new` and `/items/:id/edit` routes
- [ ] Fetch and pre-fill the form on the edit route, showing a skeleton while loading
- [ ] Implement optimistic update: reflect the save immediately, roll back and show an error toast on API failure
- [ ] Add an `onBeforeRouteLeave` guard warning the user about unsaved changes
- [ ] Ensure the form fully resets when navigating from editing item A directly to editing item B
- [ ] Add delete with a confirmation step (ties into the modal-confirmation lab)

## Expected Output

One form component correctly handling create, edit, optimistic save/rollback, and an unsaved-changes navigation guard, verified against both routes.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
