# Lab: API Gateway Pattern

## Objectives
- Design and implement a single entry point that routes, aggregates, and secures traffic to multiple backend microservices.
- Apply cross-cutting concerns (auth, rate limiting, request/response transformation) at the gateway layer instead of duplicating them per service.
- Evaluate trade-offs between a dedicated gateway (YARP/Ocelot) vs. a gateway-per-client (Backend for Frontend) architecture.
- Explain when an API Gateway becomes a bottleneck/single point of failure and how to mitigate it (scaling, caching, circuit breaking).

## Key Concepts
`API Gateway` · `Reverse Proxy` · `YARP` · `Ocelot` · `Azure API Management` · `Kong` · `Backend for Frontend (BFF)` · `Request Aggregation` · `Rate Limiting`

## Tasks
- [ ] Stand up 2-3 minimal backend microservices (e.g. catalog, orders, users).
- [ ] Configure a gateway (YARP or Ocelot) to route requests to each backend by path prefix.
- [ ] Implement request aggregation for a composite endpoint that calls 2+ backends and merges responses.
- [ ] Add centralized concerns at the gateway: JWT validation, rate limiting, response caching.
- [ ] Simulate a backend outage and observe gateway behavior without gateway-level resilience, then add a circuit breaker/timeout policy.
- [ ] Document routing rules and gateway configuration.

## Expected Output
A running gateway exposing a single base URL that transparently routes to the backend services, with a working aggregated endpoint and a demonstrated rate-limit/circuit-breaker response (e.g., 429/503) when a backend is degraded.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
