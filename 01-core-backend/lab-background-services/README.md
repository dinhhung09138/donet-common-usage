# Lab: ASP.NET Core Background Services

## Objectives
- Design and implement long-running background work in ASP.NET Core using `BackgroundService`/`IHostedService` without blocking the host's request pipeline.
- Apply the .NET Generic Host lifetime correctly — `StartAsync`, `ExecuteAsync`, `StopAsync` — including cancellation-token propagation for graceful shutdown.
- Manage scoped dependencies (e.g. `DbContext`, scoped repositories) safely from a singleton-lifetime hosted service via `IServiceScopeFactory`.
- Handle unobserved exceptions in background loops so a single failure doesn't silently kill the entire host process.
- Reason about deployment/operational trade-offs of in-process background work vs. a dedicated worker process (see `lab-worker-service`) or a job scheduler (see `lab-hangfire`).

## Key Concepts
`BackgroundService` · `IHostedService` · `IHostApplicationLifetime` · `CancellationToken` · `IServiceScopeFactory` · `PeriodicTimer` · `Graceful shutdown` · `Host shutdown timeout` · `Channel<T>`

## Tasks
- [ ] Scaffold an ASP.NET Core Web API and register a custom `BackgroundService` that runs a periodic task using `PeriodicTimer` (not `Thread.Sleep`).
- [ ] Inject `IServiceScopeFactory` into the hosted service and resolve a scoped `DbContext`/repository inside each iteration via `CreateAsyncScope()`.
- [ ] Implement a producer/consumer background service backed by `System.Threading.Channels.Channel<T>` to decouple request-time enqueue from background processing.
- [ ] Wire `IHostApplicationLifetime.ApplicationStopping` and honor the loop's `CancellationToken` so `StopAsync` completes within the host's shutdown timeout (`HostOptions.ShutdownTimeout`).
- [ ] Wrap the service's work in try/catch with structured logging so an unhandled exception is logged and the service either retries with backoff or exits cleanly, rather than crashing the process or being silently swallowed by the host.
- [ ] Add a health check (`IHealthCheck`) that reports the background service's last successful run timestamp, exposed on `/health`.
- [ ] Load-test graceful shutdown: send `SIGTERM`/Ctrl+C mid-iteration and verify in-flight work either completes or is abandoned cleanly within the shutdown window.

## Expected Output
A running ASP.NET Core service where `/health` reports the background service's liveness, log output shows periodic execution with scoped `DbContext` usage per iteration, and a `docker stop` (or Ctrl+C) against the running container/process demonstrates clean shutdown — no orphaned scope, no unobserved task exception, completion within the configured shutdown timeout.

## Implementation Walkthrough

1. **Scaffold the solution** (mirrors the `lab-automapper` layout: `.sln` + `src/<Project>/` + `tests/<Project>.Tests/`):
   ```
   dotnet new sln -n LabBackgroundServices
   dotnet new webapi -n LabBackgroundServices -o src/LabBackgroundServices --use-program-main false
   dotnet new xunit -n LabBackgroundServices.Tests -o tests/LabBackgroundServices.Tests
   dotnet sln add src/LabBackgroundServices/LabBackgroundServices.csproj tests/LabBackgroundServices.Tests/LabBackgroundServices.Tests.csproj
   dotnet add tests/LabBackgroundServices.Tests reference src/LabBackgroundServices
   ```
   `--use-program-main false` gives top-level statements in `Program.cs` — matches how the rest of the repo's Web API labs are expected to look.

2. **Add EF Core InMemory**, pinned to the SDK's own EF Core line so there's no version drift against `Microsoft.NET.Sdk.Web`'s shared framework:
   ```
   dotnet add src/LabBackgroundServices package Microsoft.EntityFrameworkCore.InMemory --version 8.0.11
   ```
   **Deliberate simplification:** a real service would point `AppDbContext` at SQL Server/PostgreSQL. The InMemory provider was chosen so the lab has zero external dependencies to run, while still exercising the actual pattern under test — a new scoped `DbContext` instance per iteration, all reading/writing the same named store (`"LabBackgroundServices"`) so data persists across scopes.

3. **File creation order** (each depends on the previous):
   - `Data/WorkItem.cs` — the entity (`Id`, `Payload`, `CreatedAtUtc`, `ProcessedAtUtc`).
   - `Data/AppDbContext.cs` — `DbSet<WorkItem>`, primary-constructor `DbContextOptions<AppDbContext>`.
   - `Reliability/BackoffPolicy.cs` — pure `NextDelay(attempt)` exponential backoff (1s → 2s → 4s → … capped at 30s), kept dependency-free so it's directly unit-testable.
   - `HealthChecks/LastRunTracker.cs` — singleton holding `DateTimeOffset? LastSuccessUtc`, the seam between the worker and the health check (no direct coupling between the two).
   - `HealthChecks/PeriodicWorkerHealthCheck.cs` — `IHealthCheck` reading `LastRunTracker`, with an optional constructor `stalenessThreshold` parameter (defaults to 15s via DI, overridable in tests).
   - `Workers/PeriodicWorker.cs` — `BackgroundService` using `PeriodicTimer` (5s tick), `IServiceScopeFactory.CreateAsyncScope()` per tick, `IHostApplicationLifetime.ApplicationStopping` registration, try/catch per iteration with `BackoffPolicy`-driven retry delay.
   - `Workers/ChannelConsumerService.cs` — `BackgroundService` draining a singleton `Channel<WorkItem>` via `Reader.ReadAllAsync(stoppingToken)`; re-resolves the work item by `Id` from its own scoped `AppDbContext` rather than reusing the detached instance carried through the channel.
   - `Program.cs` — DI wiring (see step 4) and the two endpoints (`POST /work-items`, `GET /work-items`) plus `/health`.

4. **DI/startup wiring order in `Program.cs`, with rationale:**
   - `AddDbContext<AppDbContext>(... UseInMemoryDatabase("LabBackgroundServices"))` — registered scoped (EF Core default), named store shared across all scopes.
   - `AddSingleton(Channel.CreateUnbounded<WorkItem>())` — one channel instance for the whole app lifetime; unbounded because the lab's producer (an HTTP endpoint) must never block on a full channel.
   - `AddSingleton<LastRunTracker>()` — must outlive any single request/iteration; shared by both the worker and the health check.
   - `AddHealthChecks().AddCheck<PeriodicWorkerHealthCheck>("periodic_worker")` — registered before the hosted services so the check exists the moment `/health` can be hit, even before the first tick.
   - `AddHostedService<PeriodicWorker>()` / `AddHostedService<ChannelConsumerService>()` — order between the two doesn't matter functionally (they don't depend on each other), but both are registered after their shared singletons (`Channel<WorkItem>`, `LastRunTracker`) so DI resolves cleanly.
   - `builder.Host.ConfigureHostOptions(o => o.ShutdownTimeout = TimeSpan.FromSeconds(10))` — set explicitly (rather than relying on the 5s default) so an in-flight `PeriodicWorker` iteration has a realistic window to observe cancellation and unwind.

5. **Verification — build, test, run:**
   ```
   $ dotnet build
   Build succeeded.
       0 Warning(s)
       0 Error(s)

   $ dotnet test
   Passed!  - Failed: 0, Passed: 13, Skipped: 0, Total: 13, Duration: 31 ms - LabBackgroundServices.Tests.dll (net8.0)

   $ dotnet run   # from src/LabBackgroundServices
   info: Microsoft.Hosting.Lifetime[14]
         Now listening on: http://localhost:5299
   info: Microsoft.Hosting.Lifetime[0]
         Application started. Press Ctrl+C to shut down.
   info: LabBackgroundServices.Workers.PeriodicWorker[0]
         PeriodicWorker tick: 0 unprocessed work item(s) in store.

   $ curl http://localhost:5299/health
   {"status":"Healthy","entries":{"periodic_worker":{"status":"Healthy","description":"PeriodicWorker is running.","data":{"lastSuccessUtc":"2026-07-12T02:44:59.24Z","ageSeconds":2.13}}}}

   $ curl -X POST http://localhost:5299/work-items -H "Content-Type: application/json" -d '{"payload":"hello-world"}'
   {"id":1,"payload":"hello-world","createdAtUtc":"2026-07-12T02:45:16.85Z","processedAtUtc":null}

   $ curl http://localhost:5299/work-items
   [{"id":1,"payload":"hello-world","createdAtUtc":"2026-07-12T02:45:16.85Z","processedAtUtc":"2026-07-12T02:45:16.94Z"}]
   ```
   Log excerpt confirming the channel path end-to-end:
   ```
   info: Microsoft.EntityFrameworkCore.Update[30100]
         Saved 1 entities to in-memory store.
   info: LabBackgroundServices.Workers.ChannelConsumerService[0]
         ChannelConsumerService processed work item 1.
   ```
   The item was processed (`processedAtUtc` populated) well within one `PeriodicWorker` tick interval, and `PeriodicWorker`'s own DB read (filtered on `ProcessedAtUtc == null`) never observed it as pending — evidence that the two hosted services are running concurrently against the same in-memory store via independently scoped `DbContext` instances, not sharing one.

6. **Verification — graceful shutdown (manual step, task 7 in the checklist above):**
   Sending POSIX-style signals (`kill -INT`/`-TERM`, `taskkill` without `/F`) from a non-interactive shell on Windows does **not** reliably deliver a `CTRL_C_EVENT`/`CTRL_CLOSE_EVENT` to a console-hosted `dotnet.exe` process — confirmed while building this lab: `kill -INT <pid>` and `taskkill` (graceful) both left the process running, and only `taskkill /F` (hard kill) terminated it. This is a Windows console-signal limitation, not a bug in the hosted services.
   To actually observe graceful shutdown, run `dotnet run` from an **interactive terminal** (Windows Terminal / PowerShell) and press **Ctrl+C** directly, or run the app in a container and use `docker stop` (which sends a real `SIGTERM` inside Linux). Expected log sequence:
   ```
   info: Microsoft.Hosting.Lifetime[0]
         Application is shutting down...
   info: LabBackgroundServices.Workers.PeriodicWorker[0]
         PeriodicWorker observed ApplicationStopping; current iteration will be given until shutdown timeout to finish.
   info: LabBackgroundServices.Workers.ChannelConsumerService[0]
         ChannelConsumerService stopping: channel reader completed or cancellation requested.
   info: LabBackgroundServices.Workers.PeriodicWorker[0]
         PeriodicWorker stopping: cancellation requested.
   ```
   all within the 10s `ShutdownTimeout` window — no "forcefully terminated" message from `Microsoft.Hosting.Lifetime`, no unobserved task exception.

## Common Pitfalls & Troubleshooting
- **Resolving a scoped `DbContext` directly in a hosted service's constructor** — `BackgroundService` implementations are registered as singletons, so constructor-injecting `AppDbContext` (scoped) throws `InvalidOperationException: Cannot consume scoped service ... from singleton`. Fix: inject `IServiceScopeFactory` and call `CreateAsyncScope()` inside each iteration, as done in `PeriodicWorker`/`ChannelConsumerService`.
- **Driving the loop with `Task.Delay`/`Thread.Sleep` in a `while(true)`** — doesn't honor cancellation promptly and drifts under load. `PeriodicTimer.WaitForNextTickAsync(stoppingToken)` both ticks on a fixed cadence and observes the token, so the loop exits as soon as shutdown starts rather than finishing a stray delay first.
- **Reusing the entity instance carried through `Channel<T>` for EF Core updates in a different scope** — calling `db.WorkItems.Update(item)` on an entity created in another `DbContext` (or one with a default/unset key) throws or silently no-ops against the InMemory provider. `ChannelConsumerService` instead re-fetches by `Id` (`FindAsync`) inside its own scope's `DbContext` and mutates the tracked instance.
- **Letting an unhandled exception escape `ExecuteAsync`** — an uncaught exception in a hosted service's `ExecuteAsync` faults the returned `Task`; by default the host logs it but keeps running with the service silently dead (no more ticks, no crash, no obvious signal something's wrong). `PeriodicWorker` wraps each iteration in try/catch and applies `BackoffPolicy` before retrying, so a transient failure is visible in logs and self-heals instead of quietly stopping.
- **Windows console signals don't behave like POSIX signals** — see the graceful-shutdown walkthrough note above. Don't trust `kill`/`taskkill` from a script to validate shutdown behavior on Windows; use an interactive terminal (Ctrl+C) or a Linux container (`docker stop`) instead.
- **Forgetting to set `HostOptions.ShutdownTimeout` explicitly** — the default is 5 seconds, which can be too tight for an iteration that's mid-`SaveChangesAsync` against a real (non-InMemory) database. This lab sets it to 10s via `ConfigureHostOptions` and documents why, rather than relying on the implicit default.
