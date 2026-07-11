# Lab: Print-Friendly Views (Vue)

## Objectives

- Build a dedicated print stylesheet that hides nav/chrome and reflows content for paper
- Control page breaks explicitly for tables and long content blocks
- Trigger print programmatically from a button with a pre-print data-ready guard
- Verify print output for both light content and a data table across multiple pages

## Key Concepts

`@media print` · `page-break-inside/before/after` · `window.print()` · `print-only component` · `print preview verification`

## Tasks

- [ ] Add an `@media print` stylesheet hiding nav, sidebar, and interactive controls
- [ ] Build a `PrintOnly`/`ScreenOnly` wrapper pair for content that differs between screen and print
- [ ] Control `page-break-inside: avoid` on table rows/cards so items don't split across pages
- [ ] Add a 'Print' button calling `window.print()` only after data has finished loading
- [ ] Add a print-only header (logo, generated-date) not visible on screen
- [ ] Verify the print preview for a multi-page table looks correct (repeated header not required in CSS print, but no broken rows)

## Expected Output

A screen that renders normally in-browser but produces a clean, chrome-free, correctly paginated print preview via the browser's print dialog.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
