# Lab: PDF Generation & Export (React)

## Objectives

- Generate a client-side PDF (invoice/report) from structured data
- Render an existing DOM section (e.g. a report view) to PDF preserving layout
- Support multi-page PDF generation with headers/footers/page numbers
- Trigger a download with a sensible generated filename

## Key Concepts

`jsPDF` · `html2canvas/DOM-to-PDF` · `pdf pagination` · `header/footer templates` · `Blob download`

## Tasks

- [ ] Generate a structured invoice PDF from a data object using `jsPDF` (text, table, logo image)
- [ ] Render an existing on-screen report component to PDF via `html2canvas` + `jsPDF`
- [ ] Handle content taller than one page by paginating correctly with repeated headers
- [ ] Add page numbers and a generation-timestamp footer on every page
- [ ] Trigger the download with a filename derived from the entity (`invoice-INV-1042.pdf`)
- [ ] Compare output fidelity and file size between the structured-data approach and the DOM-capture approach

## Expected Output

A multi-page, correctly paginated invoice/report PDF generated entirely client-side and downloaded with a meaningful filename.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
