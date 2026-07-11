# Lab: Sortable & Filterable Data Table (Vue)

## Objectives

- Build a data table with multi-column sort and combinable column filters
- Sync sort/filter state to the URL so the view is shareable/bookmarkable
- Implement server-side sort/filter delegation for large datasets
- Add row selection with a 'select all on page' vs 'select all matching filter' distinction

## Key Concepts

`controlled table state` · `URL-synced filters` · `server-side sort/filter` · `row selection state` · `memoized column defs`

## Tasks

- [ ] Build a table with clickable column headers cycling asc/desc/none sort
- [ ] Add per-column text/select filters that combine with AND semantics
- [ ] Sync sort + filter state into the URL query string
- [ ] Add a toggle switching between client-side sort/filter and server-delegated sort/filter
- [ ] Implement row selection with header checkbox supporting 'select all on this page' and 'select all N matching rows'
- [ ] Memoize column definitions with `computed` to avoid re-render thrash while typing in a filter

## Expected Output

A shareable table URL that reproduces the exact same sort/filter/page state when opened in a new tab, with correct bulk-selection semantics.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
