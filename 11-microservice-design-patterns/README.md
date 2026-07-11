# Module 11 — Microservice Design Patterns

Source: "Top 11 Microservice Design Patterns" infographic (reference material, not stored in this repo) — used as the pattern list for this module.

**Focus:** The classic microservice resilience, routing, and migration patterns that come up in senior/architect-level system design interviews. Each pattern gets its own standalone, runnable lab in this folder.

Note: `lab-saga-pattern`, `lab-cqrs-pattern`, `lab-event-sourcing`, and `lab-outbox-pattern` also have counterparts in [`src/03-system-design/`](../03-system-design/). The `03-system-design` versions sit in the broader system-design curriculum (CAP theorem, rate limiting, etc.); the versions here focus specifically on the microservice-pattern implementation called out by the infographic. Treat them as two independent labs on the same pattern, not duplicates to be merged.

## Labs

| Pattern | Lab | Concern |
|---|---|---|
| API Gateway | [`lab-api-gateway/`](lab-api-gateway/) | Single entry point, routing, aggregation |
| Circuit Breaker | [`lab-circuit-breaker/`](lab-circuit-breaker/) | Stop cascading failures |
| Saga | [`lab-saga-pattern/`](lab-saga-pattern/) | Distributed transactions via choreography/orchestration |
| Retry | [`lab-retry-pattern/`](lab-retry-pattern/) | Transient fault handling |
| CQRS | [`lab-cqrs-pattern/`](lab-cqrs-pattern/) | Read/write model separation |
| Sidecar | [`lab-sidecar-pattern/`](lab-sidecar-pattern/) | Cross-cutting concerns per pod |
| Event Sourcing | [`lab-event-sourcing/`](lab-event-sourcing/) | State as an append-only event log |
| Bulkhead | [`lab-bulkhead-pattern/`](lab-bulkhead-pattern/) | Resource isolation |
| Strangler Fig | [`lab-strangler-fig-pattern/`](lab-strangler-fig-pattern/) | Incremental legacy migration |
| Database per Service | [`lab-database-per-service/`](lab-database-per-service/) | Data ownership boundaries |
| Service Discovery | [`lab-service-discovery/`](lab-service-discovery/) | Dynamic instance lookup, health-based routing |
| Outbox | [`lab-outbox-pattern/`](lab-outbox-pattern/) | Atomic DB write + event publish |

Note: the source infographic is titled "Top 11" and only 10 distinct patterns were legible in the image (the 11th icon was cropped at the top edge). Service Discovery and Outbox were added on top of the infographic's list.
