# Lab: CSV Import/Export with CsvHelper

## Objectives

- Read and write CSV files using CsvHelper with strongly-typed mapping
- Implement ClassMap for explicit column-to-property mapping
- Stream large CSV files without loading them fully into memory
- Handle bad/malformed rows gracefully without aborting the entire operation
- Expose CSV export endpoint returning a streamed file response

## Key Concepts

`CsvHelper` · `ClassMap` · `TypeConverter` · `GetRecordsAsync` · `CsvWriter` · `IAsyncEnumerable` · `BadDataFound` · `streaming` · `delimiter config`

## Tasks

- [ ] Create .NET 9 project and add `CsvHelper` NuGet package
- [ ] Define a domain model and implement `ClassMap<T>` for manual column mapping
- [ ] Implement a custom `TypeConverter` for a non-standard column format (e.g., date, enum)
- [ ] Build an import endpoint: accept CSV file upload, stream-read with `GetRecordsAsync<T>()`, return parsed count
- [ ] Add header validation — reject files with missing or unexpected columns
- [ ] Configure `BadDataFound` callback to collect malformed rows instead of throwing
- [ ] Build an export endpoint: query data and stream-write with `CsvWriter` via `IAsyncEnumerable<T>`
- [ ] Support configurable delimiter (comma vs semicolon) and UTF-8 BOM encoding
- [ ] Write unit tests for ClassMap and TypeConverter; integration test for import + export endpoints

## Expected Output

Import endpoint accepts a CSV upload and returns `{ imported: N, skipped: M, errors: [...] }`. Export endpoint streams a CSV file with correct `Content-Disposition` header. No in-memory buffering of the full file in either direction.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
