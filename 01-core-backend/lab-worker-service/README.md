# Lab: .NET Worker Service (Standalone Process)

## Objectives
- Scaffold a standalone .NET Worker Service (not hosted inside a web app) using the Generic Host, and justify when this deployment shape beats an in-process `BackgroundService` or a scheduler like Hangfire.
- Package a Worker Service for production deployment as a Windows Service, a Linux `systemd` unit, and a container image.
- Configure environment-specific settings, logging, and dependency injection identically to an ASP.NET Core app, without the web pipeline.
- Implement resilient startup/shutdown behavior appropriate for an unattended, long-running OS-managed process.

## Key Concepts
`Generic Host` · `Worker Service template` · `Windows Service (sc.exe / UseWindowsService)` · `systemd (UseSystemd)` · `Container deployment` · `appsettings environment overlays` · `Graceful shutdown` · `Process supervision`

## Tasks
- [ ] Create a new project from the `dotnet new worker` template and implement the core `BackgroundService.ExecuteAsync` loop for a realistic workload (e.g. polling a queue/table and processing items).
- [ ] Wire configuration and DI (`appsettings.json` + environment overlay, `IOptions<T>`, typed HttpClient) the same way as in a web host, verifying no web-specific dependencies leak in.
- [ ] Add `UseWindowsService()` and publish/install the worker as a Windows Service (`sc.exe create`), confirming it starts on boot and logs to the Windows Event Log.
- [ ] Add `UseSystemd()`, write a `.service` unit file, and run the worker under `systemd` on Linux (or WSL), confirming `journalctl` captures its logs.
- [ ] Containerize the worker with a minimal base image, run it under Docker, and confirm `docker stop` triggers graceful shutdown within the configured timeout.
- [ ] Compare and document the operational differences (restart policy, log destination, scaling model, update/rollback story) between the Windows Service, systemd, and container deployment targets.

## Expected Output
A single Worker Service codebase successfully deployed and run in all three targets — installed as a Windows Service (or systemd unit) and as a Docker container — each demonstrating correct startup, continuous processing of the workload, and graceful shutdown on stop/restart, with logs visible through the platform-native mechanism (Event Log / journalctl / `docker logs`).

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
