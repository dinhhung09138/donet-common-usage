# Lab: Health Checks

## Objectives
- Implement liveness and readiness health check endpoints that map to Kubernetes probes
- Build a custom IHealthCheck that validates database and Redis connectivity with Degraded vs Unhealthy distinction
- Integrate community AspNetCore.HealthChecks packages for common dependencies
- Exclude health endpoints from authentication, rate limiting, and CORS middleware

## Key Concepts
`IHealthCheck` · `HealthStatus` · `MapHealthChecks` · `AspNetCore.HealthChecks.NpgSql` · `AspNetCore.HealthChecks.Redis` · `readiness vs liveness` · `HealthCheckUI` · `tag filtering`

## Tasks
- [ ] Install `AspNetCore.HealthChecks.NpgSql` and `AspNetCore.HealthChecks.Redis`; register them with `AddHealthChecks()`
- [ ] Expose two endpoints: `/health/live` (liveness — returns Healthy if the process is running) and `/health/ready` (readiness — checks DB + Redis)
- [ ] Implement a custom `IHealthCheck` for an external HTTP dependency: return `Degraded` if response time > 2s, `Unhealthy` if unreachable
- [ ] Tag checks with `"live"` and `"ready"` tags and use `MapHealthChecks` with `Predicate` to filter by tag
- [ ] Configure `HealthCheckOptions.ResponseWriter` to return a detailed JSON body (service name, status, duration per check)
- [ ] Bypass authentication middleware for health endpoints using `AllowAnonymous` or `RequireHost`
- [ ] Install `AspNetCore.HealthChecks.UI` and configure the dashboard at `/healthchecks-ui`
- [ ] Write integration tests using `WebApplicationFactory` that assert `/health/live` returns 200 and `/health/ready` reflects DB availability

## Expected Output
An API with `/health/live` and `/health/ready` endpoints, custom checks with Degraded/Unhealthy states, a HealthCheckUI dashboard, and integration tests verifying probe responses.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
