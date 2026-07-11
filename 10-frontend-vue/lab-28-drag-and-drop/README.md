# Lab: Drag-and-Drop Interactions (Vue)

## Objectives

- Implement drag-and-drop reordering within a single list
- Implement drag-and-drop between multiple containers (Kanban-style)
- Persist the reordered/moved state and sync it to the backend
- Support keyboard-accessible reordering as a fallback to pointer-only drag

## Key Concepts

`vue-draggable-next / dnd primitives` · `sortable list` · `cross-container drop zones` · `optimistic reorder persistence` · `keyboard reorder fallback`

## Tasks

- [ ] Implement a single sortable list (drag to reorder) using `vue-draggable-next` or equivalent
- [ ] Extend to a 3-column Kanban board with drag between columns
- [ ] Persist the new order/column optimistically, rolling back on API failure
- [ ] Add a keyboard-operable 'Move up/down/to column' fallback for non-pointer users
- [ ] Show a drag-preview/ghost element and a drop-indicator line
- [ ] Handle the edge case of dropping on an empty column

## Expected Output

A working Kanban board with pointer drag-and-drop across columns, optimistic persistence, and a keyboard-only reordering fallback.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
