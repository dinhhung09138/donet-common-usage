# Lab: CSV Import/Export in the Browser (React)

## Objectives

- Parse a user-uploaded CSV client-side with header mapping and type coercion
- Validate parsed rows and report per-row errors before committing an import
- Export current table/grid data to a downloaded CSV file
- Handle large CSV files without blocking the main thread

## Key Concepts

`PapaParse` · `header-to-field mapping UI` · `per-row validation report` · `Blob download` · `Web Worker parsing`

## Tasks

- [ ] Build a CSV upload that parses with PapaParse and previews the first 10 rows
- [ ] Build a column-mapping UI letting the user map CSV headers to expected fields
- [ ] Validate every row (required fields, type coercion) and show a per-row error report
- [ ] Commit only valid rows and report a final `{imported, skipped, errors}` summary
- [ ] Build a CSV export of the current table's visible rows using a `Blob` + download link
- [ ] Move parsing of large files (10k+ rows) into a Web Worker to keep the UI responsive

## Expected Output

A CSV import wizard (upload → map columns → validate → commit) plus a one-click CSV export, with large-file parsing offloaded to a Web Worker.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
