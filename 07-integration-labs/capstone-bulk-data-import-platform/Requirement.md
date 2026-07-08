# Capstone: Bulk Data Import Platform

## Business Context

Build an enterprise-grade ETL/data import service: clients upload CSV or Excel files with 100k–1M rows, system validates each row, commits valid rows in batches, reports per-row errors, and sends real-time progress. This is a common requirement in ERP, HR, and financial data platforms — and a frequent practical coding test at Toptal.

## Prerequisite Labs

- `lab-csv-import-export`
- `lab-excel-reports`
- `lab-bulk-import-pipeline`
- `lab-hangfire-advanced`
- `lab-fluentvalidation`
- `lab-signalr-hubs`
- `lab-caching-patterns`
- `lab-background-services`

## Functional Requirements

- Accept CSV and XLSX uploads up to 500MB via streaming multipart
- Row-level validation with FluentValidation: per-row error report (rowNumber, field, message)
- Two import modes: `partial` (commit valid rows, skip invalid) and `strict` (all-or-nothing)
- Real-time progress via SignalR: Uploading → Validating → Importing → Complete
- Idempotent re-run: same file re-uploaded does not create duplicates (hash-based dedup key per row)
- Import result report: downloadable CSV of all failed rows with error details
- Hangfire dashboard visible to admin users showing job queue and status

## Non-Functional Requirements

- Never load entire file into memory — streaming row-by-row processing
- Batch DB writes: 500 rows per `BulkInsert` (EFC.BulkExtensions or SqlBulkCopy)
- Channel<T> bounded to 2000 rows — backpressure prevents memory spike
- Progress updates throttled: max 1 SignalR push per second (avoid flooding)
- Redis distributed lock: prevent same file being processed twice concurrently
- Import job must survive application restart (Hangfire persistent storage)

## Architecture

```
POST /imports/upload (streaming multipart):
  → stream file to Azure Blob (temp container)
  → compute SHA-256 hash of file content
  → check Redis: if hash already processing → 409 Conflict
  → acquire Redis distributed lock (key = hash, TTL = 10 min)
  → enqueue Hangfire job (ImportJob) with blobName + importId + mode
  → return 202 Accepted + importId

Hangfire ImportJob:
  → download blob stream (streaming, not buffering)
  → detect format (CSV vs XLSX by magic bytes)
  → start Channel<T> producer-consumer:
      Producer: stream rows from CsvHelper/EPPlus → Channel.Writer
      Consumer: batch 500 rows → validate → insert or collect errors
  → track progress → throttled SignalR push every 1s
  → on completion: write error report CSV to Blob, update ImportJob record (status, successCount, failCount, errorReportUrl)
  → release Redis lock
```

## Implementation Steps

1. **ImportJob entity:** `Id`, `FileName`, `FileHash` (SHA-256), `Status`, `TotalRows`, `SuccessRows`, `FailedRows`, `Mode` (Partial/Strict), `ErrorReportBlobUrl`, `CreatedAt`, `CompletedAt`
2. **Streaming upload:** read `Request.Body` to compute SHA-256 in-stream while uploading to Azure Blob (no temp file on disk)
3. **Redis lock:** `IDistributedLock` with `StackExchange.Redis`; `SETNX imports:lock:{hash}` with TTL; 409 if lock exists
4. **Hangfire job:** `[DisableConcurrentExecution(600)]` attribute; PostgreSQL storage for restart survival
5. **Channel pipeline:** `Channel.CreateBounded<ImportRow>(2000)`; producer streams from blob; consumer pops in batches of 500
6. **CSV streaming:** `CsvReader.GetRecordsAsync<T>()` — truly async, row-by-row, `BadDataFound` handler collects parse errors
7. **XLSX streaming:** EPPlus `LoadFromCollection` with chunk iterator via `IAsyncEnumerable`
8. **FluentValidation per-row:** `ImportRowValidator`; validate each row; collect `ValidationResult` per row number
9. **Batch insert:** for partial mode — `BulkInsertAsync` (EFCore.BulkExtensions) for valid rows; rollback chunk on strict mode failure
10. **Idempotency:** `ImportKey` = SHA-256 of (entityId + relevant fields); unique constraint; `ON CONFLICT DO NOTHING` for re-runs
11. **SignalR throttle:** `lastPushAt` timestamp; only push if `now - lastPushAt > 1s`; final push always sent
12. **Error report:** failed rows written to `CsvWriter` stream → Azure Blob; SAS URL returned in job result
13. **Integration tests:** upload test CSV via WebApplicationFactory; verify row counts, error report URL, idempotent re-run

## Expected Deliverables

- Working import that handles a 100,000-row CSV without memory spike (confirm via memory profiling)
- Screenshot of Hangfire dashboard showing job progress
- ADR: "Partial commit vs strict all-or-nothing — when to use each"
- PR description covering Channel<T> backpressure and batch insert strategy

## Interview Talking Points

- How do you import 1M rows without running out of memory? (streaming + Channel<T> bounded buffer + batch insert; never load all rows at once)
- What happens if the Hangfire worker crashes at row 500,000? (Hangfire retries from beginning; idempotency key prevents duplicate inserts for already-committed rows)
- How do you report per-row errors while still committing valid rows? (partial mode: accumulate errors per chunk, continue processing; strict mode: first error aborts entire job)
- How do you prevent the same file from being processed twice simultaneously? (Redis distributed lock on file hash; 409 if lock exists)
- Why batch 500 rows instead of inserting row-by-row? (SqlBulkCopy or BulkInsert reduces round-trips; 500 rows = ~1 batch per second at typical throughput)
