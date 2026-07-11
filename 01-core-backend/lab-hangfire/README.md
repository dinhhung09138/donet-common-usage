# Lab: Hangfire Background Jobs

## Objectives
- Choose the correct Hangfire job type (fire-and-forget, delayed, recurring) for a given business scenario and justify the trade-off vs. an in-process `BackgroundService`.
- Configure a persistent Hangfire storage provider so jobs survive an application restart and support multi-instance deployment.
- Operate and secure the Hangfire Dashboard for job observability in a production-like environment.
- Design idempotent, retry-safe job methods that tolerate Hangfire's at-least-once execution guarantee.

## Key Concepts
`Fire-and-forget job` · `Delayed job` · `Recurring job (CRON)` · `Hangfire Dashboard` · `Storage provider` · `Automatic retries` · `Job idempotency` · `Job filters` · `Server/worker process`

## Tasks
- [ ] Add Hangfire to an ASP.NET Core API, configure a persistent storage provider (SQL Server or PostgreSQL), and start the Hangfire server alongside the web host.
- [ ] Enqueue a fire-and-forget job (`BackgroundJob.Enqueue`) from an API endpoint (e.g. send a welcome email after signup) and verify it executes asynchronously.
- [ ] Schedule a delayed job (`BackgroundJob.Schedule`) that runs a fixed interval after enqueue (e.g. send a follow-up reminder after 24 hours).
- [ ] Define a recurring job (`RecurringJob.AddOrUpdate`) using a CRON expression (e.g. nightly cleanup) and verify it fires on schedule.
- [ ] Secure the Hangfire Dashboard behind authentication/authorization (`IDashboardAuthorizationFilter`) instead of leaving it open in `Development` only.
- [ ] Make a job method idempotent (e.g. check-then-act guarded by a unique key) and verify correctness under Hangfire's default automatic-retry behavior when the job throws mid-execution.
- [ ] Kill the application mid-job and confirm the job is picked up and completed after restart (proving persistence survives process loss).

## Expected Output
A running ASP.NET Core app exposing the Hangfire Dashboard at `/hangfire` (authenticated), with a fire-and-forget job, a delayed job, and a CRON-scheduled recurring job all visible in the dashboard's Succeeded/Scheduled/Recurring views, and a demonstrated restart-survival test showing an in-flight job resumes/completes after the process is killed and relaunched.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
