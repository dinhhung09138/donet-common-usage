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
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
