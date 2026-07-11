# Lab: Pagination Patterns (React)

## Objectives

- Implement client-side pagination for small in-memory datasets
- Implement server-driven page-number pagination synced to the URL query string
- Implement cursor-based 'load more' pagination for large/streaming datasets
- Preserve pagination state across navigation (back button returns to the same page)

## Key Concepts

`client-side slicing` · `server pagination (page/pageSize)` · `cursor pagination` · `URL as state source` · `scroll restoration`

## Tasks

- [ ] Build client-side pagination (slice an in-memory array) with page-size selector
- [ ] Build server-driven pagination reading/writing `?page=&pageSize=` via `useSearchParams`
- [ ] Implement cursor-based 'load more' consuming a mock `nextCursor` API response
- [ ] Verify browser back navigation returns to the previously viewed page, not page 1
- [ ] Add a page-jump input with bounds validation (can't jump past last page)
- [ ] Show total-count and current-range ('Showing 21-40 of 137') text

## Expected Output

Three working pagination modes (client, page-number/URL-synced, cursor load-more) on the same dataset, switchable via a toggle.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
