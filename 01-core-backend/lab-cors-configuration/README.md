# Lab: CORS Configuration

## Objectives
- Understand why browsers enforce CORS and how the preflight mechanism works
- Configure named CORS policies and apply them globally and per-endpoint
- Handle the AllowCredentials + AllowAnyOrigin conflict correctly
- Test CORS behaviour with a real browser-based client

## Key Concepts
`AddCors` · `WithOrigins` · `AllowCredentials` · `AllowAnyOrigin conflict` · `PreflightMaxAge` · `[EnableCors]` · `[DisableCors]` · `middleware ordering` · `SignalR CORS`

## Tasks
- [ ] Register two named CORS policies: `PublicApi` (any origin, no credentials) and `TrustedClients` (specific origins + credentials)
- [ ] Apply `PublicApi` globally via `app.UseCors("PublicApi")` — verify middleware order (before `UseRouting`)
- [ ] Override with `[EnableCors("TrustedClients")]` on a specific endpoint; verify `[DisableCors]` suppresses CORS headers
- [ ] Trigger and inspect a preflight OPTIONS request using a browser DevTools or `curl -X OPTIONS`; confirm `Access-Control-Allow-Methods` and `Access-Control-Max-Age` headers
- [ ] Demonstrate the runtime exception when `AllowAnyOrigin()` is combined with `AllowCredentials()`; fix it using `SetIsOriginAllowed(_ => true)`
- [ ] Configure `PreflightMaxAge` to 10 minutes and verify the `Access-Control-Max-Age` response header
- [ ] Add a SignalR hub and configure its CORS to allow credentials from specific origins
- [ ] Write integration tests using `WebApplicationFactory` that assert correct CORS headers for allowed and disallowed origins

## Expected Output
An API with two CORS policies, correct preflight handling, per-endpoint overrides, and passing integration tests for origin allow/deny scenarios.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
