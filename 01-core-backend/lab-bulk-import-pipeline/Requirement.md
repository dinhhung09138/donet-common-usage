# Lab: Bulk Data Import Pipeline

## Objectives

- Design a production-grade bulk import pipeline that handles tens of thousands of rows
- Apply row-level validation with FluentValidation and accumulate per-row error reports
- Track progress in real time and report it to the client via SignalR
- Make the import operation idempotent so re-uploading the same file is safe
- Offload long-running import to a Hangfire background job

## Tasks

- [ ] Create .NET 9 project with ASP.NET Core + Hangfire + SignalR
- [ ] Implement multipart file upload endpoint that enqueues an import job and returns a job ID
- [ ] Build the import job: read source file in configurable chunks (e.g., 500 rows/batch)
- [ ] Apply row-level `AbstractValidator<T>` — collect failures without aborting the batch
- [ ] Build `ImportResultDto`: total, imported, skipped, list of `{ rowNumber, field, error }`
- [ ] Implement idempotency key derived from file hash — detect and reject duplicate imports
- [ ] Report progress (percentage complete) to the client via a SignalR hub (`IHubContext`)
- [ ] Decision point: implement both strategies and compare
  - Partial commit — commit valid rows, skip invalid ones
  - All-or-nothing — roll back entire import if any row fails
- [ ] Implement `Channel<T>` producer-consumer: reader produces rows, validator + writer consume
- [ ] Write integration test: upload a 10,000-row file, assert result DTO and idempotency on re-upload

## Expected Output

Client uploads a file, receives a job ID, connects to SignalR hub, and receives progress events until import completes. Final result is a JSON report with per-row errors. Re-uploading the same file returns a cached result without re-processing.

## Key Concepts Practiced

`Chunked import` · `FluentValidation per row` · `import result DTO` · `IProgress<T>` · `SignalR` · `idempotency key` · `Hangfire` · `partial commit vs rollback` · `Channel<T>` · `producer-consumer`

## Status

- [ ] Completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/`
- [ ] ADR written → `src/05-technical-english/design-docs/` (partial commit vs all-or-nothing)
