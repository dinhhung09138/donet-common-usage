# Lab: Advanced Data Grid (React)

## Objectives

- Render large datasets performantly using row virtualization
- Implement resizable and reorderable columns persisted to local storage
- Support inline cell editing with per-cell validation
- Support column-level pinning/freezing for wide tables

## Key Concepts

`react-window/react-virtual` · `virtualization` · `column resize/reorder` · `inline cell editing` · `persisted grid layout` · `pinned columns`

## Tasks

- [ ] Render a 10,000-row dataset with row virtualization (`react-window` or `@tanstack/react-virtual`)
- [ ] Measure and note the FPS/render-time difference vs a non-virtualized render
- [ ] Implement drag-to-resize and drag-to-reorder columns, persisting layout to `localStorage`
- [ ] Add inline cell editing (double-click to edit) with per-cell validation and Escape-to-cancel
- [ ] Implement pinning a column to the left edge while the rest scrolls horizontally
- [ ] Add a CSV export of the currently visible/filtered rows

## Expected Output

A 10k-row grid that scrolls smoothly, with resizable/pinned columns and inline editing, plus a documented before/after virtualization performance measurement.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
