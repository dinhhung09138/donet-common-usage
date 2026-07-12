# Lab: Bulk Data Import Pipeline

## Objectives

- Design a production-grade bulk import pipeline that handles tens of thousands of rows
- Apply row-level validation with FluentValidation and accumulate per-row error reports
- Track progress in real time and report it to the client via SignalR
- Make the import operation idempotent so re-uploading the same file is safe
- Offload long-running import to a Hangfire background job

## Key Concepts

`Chunked import` · `FluentValidation per row` · `import result DTO` · `IProgress<T>` · `SignalR` · `idempotency key` · `Hangfire` · `partial commit vs rollback` · `Channel<T>` · `producer-consumer`

## Tasks

- [x] Create .NET project with ASP.NET Core + Hangfire + SignalR (net8.0 — see Implementation Walkthrough for why)
- [x] Implement multipart file upload endpoint that enqueues an import job and returns a job ID
- [x] Build the import job: read source file in configurable chunks (e.g., 500 rows/batch)
- [x] Apply row-level `AbstractValidator<T>` — collect failures without aborting the batch
- [x] Build `ImportResultDto`: total, imported, skipped, list of `{ rowNumber, field, error }`
- [x] Implement idempotency key derived from file hash — detect and reject duplicate imports
- [x] Report progress (percentage complete) to the client via a SignalR hub (`IHubContext`)
- [x] Decision point: implement both strategies and compare
  - Partial commit — commit valid rows, skip invalid ones
  - All-or-nothing — roll back entire import if any row fails
- [x] Implement `Channel<T>` producer-consumer: reader produces rows, validator + writer consume
- [x] Write integration test: upload a 10,000-row file, assert result DTO and idempotency on re-upload

## Expected Output

Client uploads a file, receives a job ID, connects to SignalR hub, and receives progress events until import completes. Final result is a JSON report with per-row errors. Re-uploading the same file returns a cached result without re-processing.

## Implementation Walkthrough

1. **Scaffold the solution** (mirrors `lab-background-services`: `.sln` + `src/<Project>/` + `tests/<Project>.Tests/`), on **net8.0** rather than the .NET 9 named in the Tasks list — kept consistent with every other implemented lab in this module (`lab-automapper`, `lab-background-services`) so there's no version drift within `01-core-backend`:

   ```bash
   dotnet new sln -n LabBulkImportPipeline
   dotnet new webapi -n LabBulkImportPipeline -o src/LabBulkImportPipeline --use-program-main false
   dotnet new xunit -n LabBulkImportPipeline.Tests -o tests/LabBulkImportPipeline.Tests
   dotnet sln add src/LabBulkImportPipeline/LabBulkImportPipeline.csproj tests/LabBulkImportPipeline.Tests/LabBulkImportPipeline.Tests.csproj
   dotnet add tests/LabBulkImportPipeline.Tests reference src/LabBulkImportPipeline
   ```

2. **Packages**, chosen to keep the lab zero-external-dependency (no SQL Server/LocalDB, no message broker):
   - `src/LabBulkImportPipeline`: `Microsoft.EntityFrameworkCore.InMemory` 8.0.11, `CsvHelper` 33.0.1, `FluentValidation` 11.11.0, `Hangfire.Core` + `Hangfire.AspNetCore` 1.8.14, `Hangfire.MemoryStorage` 1.8.1.1.
   - `tests/LabBulkImportPipeline.Tests`: `Microsoft.AspNetCore.Mvc.Testing` 8.0.11 (for `WebApplicationFactory<Program>`), `Microsoft.AspNetCore.SignalR.Client` 8.0.11 (for the progress-event test).
   - **`Hangfire.MemoryStorage`** was chosen over `Hangfire.SqlServer` specifically so `dotnet run` works with no external services — the trade-off (documented for the record) is that queued jobs are lost on process restart, which is fine for a lab but not for production.

3. **File creation order** (each depends on the previous):
   - `Data/ImportedRecord.cs` — the imported entity (`JobId`, `RowNumber`, `Name`, `Email`, `Amount`).
   - `Data/ImportJobStatus.cs` — `Processing | Completed | Failed`.
   - `Data/ImportJobRecord.cs` — the idempotency/status record: `JobId` (PK), `FileHash`, `Strategy`, `Status`, `ResultJson`, `CreatedAtUtc`, `CompletedAtUtc`.
   - `Data/AppDbContext.cs` — EF Core InMemory, `ImportJobRecord.JobId` as key, an index on `FileHash` for the duplicate lookup.
   - `Import/ImportRowDto.cs`, `RowError.cs`, `ImportResultDto.cs` — the shapes moving through the pipeline. **`ImportRowDto.Amount` is kept as `string`, not `decimal`**, deliberately: it lets a non-numeric value fail as a normal per-row `FluentValidation` error (`RowError`) instead of throwing during CSV parsing and killing the whole read.
   - `Validation/ImportRowValidator.cs` — `AbstractValidator<ImportRowDto>`: `Name` required, `Email` required + `EmailAddress()`, `Amount` required + must parse to a non-negative decimal.
   - `Import/ChunkedCsvReader.cs` — reads via `CsvHelper` with `MissingFieldFound = null` / `HeaderValidated = null` (see Pitfalls), writes each row into a `Channel<ImportRowDto>`, calls `writer.Complete()` (or `Complete(exception)` on failure) in a `finally` so the consumer's `await foreach` always terminates.
   - `Hubs/ImportProgressHub.cs` — a one-method hub (`JoinJob(jobId)` → `Groups.AddToGroupAsync`), so progress pushes can target only the client(s) watching a specific job instead of broadcasting to everyone connected.
   - `Import/ImportStrategy.cs` — `PartialCommit | AllOrNothing`.
   - `Import/ImportJob.cs` — the Hangfire job body (detailed in step 5).
   - `Program.cs` — DI wiring and the two HTTP endpoints (step 6).

4. **Chunking mechanics**: `ChunkedCsvReader` is a pure producer — it doesn't batch internally, it just writes one `ImportRowDto` per data row into a bounded `Channel<ImportRowDto>` (`BoundedChannelOptions(BatchSize * 2)`, `SingleReader = SingleWriter = true`). `ImportJob` is the consumer and owns the actual "500 rows/batch" behavior: it accumulates valid rows into a `List<ImportedRecord>` and calls `SaveChangesAsync` every `BatchSize` (500) rows, which is also when it emits a SignalR progress event. This keeps the reader dead simple and puts all batching/commit-strategy logic in one place.

5. **The two commit strategies**, both implemented in `ImportJob.RunAsync` and selected by the `strategy` query parameter (default `PartialCommit`):
   - **`PartialCommit`** — `SaveChangesAsync` is called every 500 valid rows as they're read; invalid rows are recorded in `errors` but never block the batch. A crash mid-import leaves whatever was already committed in place.
   - **`AllOrNothing`** — every row is validated and staged into an in-memory `List<ImportedRecord>` across the *entire* file; `SaveChangesAsync` is called exactly once at the end, and only if `errors.Count == 0`. If even one row is invalid, nothing is persisted (`imported` is reset to `0` in the result).
   - **Observed comparison** (from `PostImport_AllOrNothingWithInvalidRows_ImportsNothing`, a 200-row file with 1-in-10 invalid rows): `PartialCommit` on the same shaped file imports the ~180 valid rows and reports 20 `RowError`s; `AllOrNothing` reports `Imported: 0` — same validation pass, opposite persistence outcome. The trade-off: `PartialCommit` gives you a partially-usable dataset immediately and cheap incremental memory use (batches are discarded after each `SaveChangesAsync`); `AllOrNothing` gives you a clean all-or-nothing guarantee at the cost of holding the entire valid-row set in memory for the whole run — a real (non-InMemory) implementation would use a database transaction instead of an in-memory list for the staged rows.

6. **DI/startup wiring in `Program.cs`, with rationale**:
   - `AddDbContext<AppDbContext>(... UseInMemoryDatabase("LabBulkImportPipeline"))` — scoped, one named store shared by the HTTP request that creates the `ImportJobRecord` and the Hangfire-invoked `ImportJob` that later updates it.
   - `AddHangfire(cfg => cfg.UseMemoryStorage())` + `AddHangfireServer()` — registering `Hangfire.AspNetCore` this way also registers `AspNetCoreJobActivator`, which creates a fresh DI scope per job execution. That's what makes it safe for `ImportJob` to constructor-inject the scoped `AppDbContext` directly (see Pitfalls — no manual `IServiceScopeFactory` needed here, unlike `lab-background-services`'s `BackgroundService`).
   - `AddSignalR()` + `AddScoped<ImportJob>()` registered before `MapHub<ImportProgressHub>("/hubs/import-progress")`.
   - `POST /imports` hashes the uploaded file (`SHA256`), checks `ImportJobs` for a `Completed` row with the same `FileHash` (returns the cached `ImportResultDto` with `FromCache = true` if found), otherwise saves the upload to a temp path (`Path.GetTempPath()/lab-bulk-import-pipeline-uploads/{jobId}.csv`) and calls `IBackgroundJobClient.Enqueue<ImportJob>(j => j.RunAsync(jobId, path, strategy, CancellationToken.None))`. The file is saved to disk rather than kept as a stream because Hangfire serializes job arguments — an open `IFormFile`/`Stream` can't survive that.
   - `GET /imports/{jobId}` returns `202 Accepted` while `Status == Processing`, otherwise deserializes and returns the stored `ResultJson`.

7. **Verification — build, test, run**:

   ```bash
   $ dotnet build
   Build succeeded.
       0 Warning(s)
       0 Error(s)

   $ dotnet test
   Passed!  - Failed: 0, Passed: 11, Skipped: 0, Total: 11, Duration: 3 s - LabBulkImportPipeline.Tests.dll (net8.0)
   ```
   The 11 tests: 6 `ImportRowValidatorTests` (1 valid-row case + 5 invalid-row `[Theory]` cases), 2 `ChunkedCsvReaderTests` (well-formed CSV, and a short row with a missing trailing field), and 3 integration tests against a real in-process `WebApplicationFactory<Program>` — a 10,000-row upload with 1-in-50 invalid rows asserting exact counts and idempotent re-upload, an `AllOrNothing` run confirming zero rows persisted when any row is invalid, and a SignalR test that opens a real `HubConnection` (LongPolling transport, `TestServer`-backed handler), joins the job's group, and asserts at least one `progress` event with the correct `jobId` arrives before the job completes.

   Manual run:

   ```bash
   $ dotnet run   # from src/LabBulkImportPipeline
   info: Microsoft.Hosting.Lifetime[14]
         Now listening on: http://localhost:5299

   $ curl -s -X POST "http://localhost:5299/imports?strategy=PartialCommit" -F "file=@sample.csv;type=text/csv"
   {"jobId":"89a471bc629949dd8b0b6f8ef4ace852"}

   $ curl -s http://localhost:5299/imports/89a471bc629949dd8b0b6f8ef4ace852
   {"jobId":"89a471bc629949dd8b0b6f8ef4ace852","status":"Completed","total":20,"imported":16,"skipped":4,
    "errors":[{"rowNumber":5,"field":"Email","error":"Email is not a valid email address."}, ...],
    "fromCache":false}

   # re-upload the identical file
   $ curl -s -X POST "http://localhost:5299/imports?strategy=PartialCommit" -F "file=@sample.csv;type=text/csv"
   {"jobId":"89a471bc629949dd8b0b6f8ef4ace852", ..., "fromCache":true}
   ```
   `sample.csv` was a 20-row file with every 5th row given an invalid email; the counts (16 imported / 4 skipped) and re-upload's `fromCache: true` matched expectations exactly, with the *same* `jobId` returned on re-upload rather than a new one.

## Common Pitfalls & Troubleshooting

- **`AbstractValidator<T>` throwing on a malformed CSV row instead of reporting it as a `RowError`** — if `ImportRowDto.Amount` were typed as `decimal`, a non-numeric CSV value would throw inside `CsvHelper`'s type conversion before validation ever runs, killing the whole read instead of producing one row-level error. Keeping `Amount` as `string` on the DTO and validating it with `Must(a => decimal.TryParse(a, out var v) && v >= 0)` turns a would-be exception into a normal, reportable `RowError`.
- **`CsvHelper` throwing `MissingFieldException`/`HeaderValidationException` on a short or reordered row** — the default `CsvConfiguration` is strict about header match and field count, which is unrealistic for "real world messy CSV" bulk-import scenarios. Setting `HeaderValidated = null` and `MissingFieldFound = null` makes a missing field resolve to `null`/empty string (caught by `NotEmpty()` in the validator) instead of throwing and aborting the entire import.
- **Resolving a scoped `AppDbContext` in `ImportJob`'s constructor** — unlike a `BackgroundService` (always a DI singleton, per `lab-background-services`), a Hangfire job class registered via `AddHangfire()`/`AddHangfireServer()` is resolved by `AspNetCoreJobActivator`, which creates a new DI scope **per job execution**. Constructor-injecting scoped `AppDbContext` here is safe and doesn't need the `IServiceScopeFactory` dance — using `IServiceScopeFactory` anyway would just be redundant.
- **Hangfire job arguments must be serializable** — the initial design considered passing the uploaded `IFormFile`/stream directly to `ImportJob.RunAsync`. Hangfire serializes job arguments to its storage (even `MemoryStorage`) before queuing, so a live stream can't survive the round trip. The fix: save the upload to a temp file in the endpoint and pass the file *path* (a string) to the job instead.
- **`Hangfire.MemoryStorage` NuGet package name is easy to get wrong** — it's `Hangfire.MemoryStorage` (a separate, community-maintained package), not `Hangfire.InMemory` or a built-in option of `Hangfire.Core`. `AddHangfire(cfg => cfg.UseMemoryStorage())` requires the `Hangfire.MemoryStorage` package reference specifically.
- **EF Core InMemory doesn't enforce unique constraints** — the idempotency check can't rely on a DB-level unique index on `FileHash` throwing on insert. It's implemented as an explicit query-then-decide in the `POST /imports` endpoint (`Where(j => j.FileHash == hash && j.Status == Completed)`) before any write happens. A real (non-InMemory) provider could additionally enforce this with a unique index as a defense-in-depth measure against concurrent duplicate uploads racing the check.
- **SignalR `HubConnection` over `TestServer` needs `LongPolling`, not WebSockets** — `WebApplicationFactory`'s in-memory `TestServer` doesn't support the WebSockets transport SignalR defaults to, so a `HubConnection` built against it silently fails to connect (or throws unhelpfully) unless `options.Transports = HttpTransportType.LongPolling` is set explicitly, alongside `options.HttpMessageHandlerFactory = _ => factory.Server.CreateHandler()`.
- **Progress events sent before the client joins the hub group are lost** — SignalR groups only deliver to members *at send time*; there's no replay buffer. In the integration test, the client must call `JoinJob(jobId)` immediately after receiving the `jobId` from `POST /imports`, and the test file is sized large enough (20,000 rows) that the first progress event (at row 500) reliably lands after the join completes rather than racing it.
