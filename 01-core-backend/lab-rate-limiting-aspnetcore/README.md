# Lab: Rate Limiting in ASP.NET Core

## Objectives
- Implement all 4 built-in ASP.NET Core 7+ rate limiting algorithms and understand their trade-offs
- Apply per-user rate limiting using the authenticated user's claim as a partition key
- Return standard 429 responses with Retry-After headers
- Exempt health check and webhook endpoints from global rate limiting

## Key Concepts
`AddRateLimiter` · `FixedWindowRateLimiter` · `SlidingWindowRateLimiter` · `TokenBucketRateLimiter` · `ConcurrencyLimiter` · `partition key` · `OnRejected` · `429 Retry-After` · `[EnableRateLimiting]`

## Tasks
- [ ] Configure a global `FixedWindowRateLimiter` (100 req/min) as the default policy; verify 429 response on breach
- [ ] Add a `SlidingWindowRateLimiter` named `"api"` (100 req/min, 4 segments); compare behaviour with fixed window under burst traffic
- [ ] Add a `TokenBucketRateLimiter` named `"upload"` (10 tokens, replenish 2/s) for file upload endpoints
- [ ] Add a `ConcurrencyLimiter` named `"expensive"` (max 5 concurrent) for a slow endpoint
- [ ] Implement per-user partitioning: use `httpContext.User.FindFirst(ClaimTypes.NameIdentifier)` as partition key; anonymous users share a single partition
- [ ] Customize `OnRejected` to write a `429 Too Many Requests` response with `Retry-After` header (seconds until window resets) and a ProblemDetails body
- [ ] Apply `[EnableRateLimiting("api")]` to a route group and `[DisableRateLimiting]` to `/health/live` and a webhook endpoint
- [ ] Write integration tests asserting that the 11th request in a fixed-window window returns 429 with a `Retry-After` header

## Expected Output
An API with 4 distinct rate limiting policies, per-user partitioning, correct 429 + Retry-After responses, and exempted endpoints.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
