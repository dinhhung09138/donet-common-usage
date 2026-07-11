# Lab: Serilog Structured Logging

## Objectives

- Set up Serilog in ASP.NET Core with multiple sinks
- Understand the difference between plain-text logs and structured logs
- Add enrichers to automatically attach metadata to every log entry
- Configure log level per namespace to control verbosity
- Use destructuring to log complex objects as structured data

## Key Concepts

`Sink` · `Enricher` · `Destructuring (@)` · `LogContext` · `Minimum level override` · `Message template` · `Seq`

## Tasks

- [ ] Install Serilog packages (`Serilog.AspNetCore`, `Serilog.Sinks.Console`, `Serilog.Sinks.File`, `Serilog.Sinks.Seq`, `Serilog.Enrichers.Environment`, `Serilog.Enrichers.Thread`) and wire up `builder.Host.UseSerilog(...)` reading from configuration
- [ ] Configure `appsettings.json`: minimum level with per-namespace overrides (e.g. `Microsoft.AspNetCore` → `Warning`), console/file/Seq sinks, and enrichers (`FromLogContext`, `WithMachineName`, `WithThreadId`, `WithEnvironmentName`)
- [ ] Log a complex object using the `@` destructuring operator (e.g. `logger.LogInformation("Order created {@Order}", order)`) instead of string concatenation
- [ ] Add per-request enrichment via `LogContext.PushProperty` (e.g. `RequestPath`, `UserId`) in middleware
- [ ] Run Seq locally via Docker Compose (`datalust/seq` image) and verify logs arrive with full properties
- [ ] Write a side-by-side comparison of a plain-text log statement vs. an equivalent structured log statement for the same event, and demonstrate that only the structured version is queryable by field in Seq (e.g. `UserId = '123'`, `Amount > 100`)

## Expected Output

Console output in JSON format (one JSON object per log entry); a rolling file at `logs/log-YYYYMMDD.txt`; Seq UI running at `http://localhost:8080` showing logs with full structured properties; a Seq query such as `Amount > 100` correctly filtering matching orders.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
