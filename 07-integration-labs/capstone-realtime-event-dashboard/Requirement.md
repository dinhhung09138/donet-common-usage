# Capstone: Real-Time Event Dashboard

## Business Context

Build an operations monitoring dashboard that displays real-time metrics, alerts, and event streams for SaaS products. Common in fintech trading platforms, DevOps monitoring tools, and IoT dashboards. This pattern combines event sourcing with real-time delivery — a favourite at Toptal system design interviews.

## Prerequisite Labs

- `lab-signalr-scaleout`
- `lab-event-sourcing`
- `lab-cqrs-pattern`
- `lab-masstransit-rabbitmq`
- `lab-caching-patterns`
- `lab-rate-limiting-aspnetcore`
- `lab-output-caching`

## Functional Requirements

- Events flow in from multiple sources (API calls, background jobs, external webhooks)
- Dashboard clients subscribe to event streams by category (orders, payments, errors, system)
- Aggregate metrics displayed: events/second, error rate, P99 latency (sliding 5-minute window)
- Event replay: client can request the last 1000 events for any category on connect
- Alert rule engine: trigger alert when error rate > 5% over 60s — push alert to all admin clients
- Event history queryable with filters (category, severity, time range) via CQRS read model

## Non-Functional Requirements

- SignalR scaled horizontally via Redis backplane (multiple server instances)
- Events/second metric: recalculated every 5s, never queries DB (Redis counter only)
- Event history query: < 200ms P99 (read model in PostgreSQL with covering index)
- Alert evaluation runs as a recurring Hangfire job (every 10s) — must be idempotent
- Rate limit: 10 events/second per source to prevent event flooding

## Architecture

```
Event sources → POST /events (rate limited per source)
  → publish EventCreated to MassTransit (RabbitMQ)

EventCreated consumer:
  → append to Event Store (append-only table with category + sequence)
  → update CQRS read model (EventSummary projection)
  → increment Redis counter: events:{category}:{timestamp_bucket}
  → push to SignalR group: dashboard:{category}

Hangfire job (every 10s):
  → read Redis counters for last 60s
  → calculate error rate
  → if threshold exceeded → publish Alert → SignalR push to admins group

Dashboard client connects:
  → authenticate JWT
  → subscribe to SignalR groups (by category)
  → call GET /events/recent?category=orders&limit=1000 (CQRS read model, output cached)
```

## Implementation Steps

1. **Event Store:** `Event` table — Id, Category, Severity, Payload (JSONB), Timestamp, SequenceNumber (per category); append-only (no UPDATE/DELETE)
2. **CQRS write side:** `EventCreatedCommand` → `EventCreatedHandler` appends to store
3. **CQRS read model:** `EventSummary` table — denormalized, rebuilt via projection; `EventSummaryProjection` updates on each event
4. **MassTransit:** publish `EventCreated` from write handler; consumer updates read model + Redis + SignalR
5. **Redis counters:** `INCR events:{category}:{minute_bucket}` with TTL 10 minutes; sliding window via LRANGE on sorted set
6. **SignalR + Redis backplane:** `AddStackExchangeRedisSignalR`; groups per category; `IHubContext<DashboardHub>` called from consumer
7. **Event replay on connect:** `OnConnectedAsync` pushes last 1000 events from read model to connecting client's connection ID
8. **Alert engine:** Hangfire recurring job reads Redis; evaluates rules from `AlertRuleOptions`; publishes `AlertTriggered` event
9. **Rate limiting:** `AddRateLimiter` with `FixedWindowRateLimiter`, partition by source API key; 429 on breach
10. **Output caching:** cache `/events/recent` per category with 5s expiry; evict via `IOutputCacheStore.EvictByTagAsync` when new event arrives in that category
11. **Integration tests:** real RabbitMQ + Redis via TestContainers; assert SignalR messages received

## Expected Deliverables

- Dashboard with working event stream (can test with a script posting events)
- Architecture diagram: event flow from source to SignalR client
- ADR: "Event sourcing append-only store vs traditional mutable events table"
- PR description covering CQRS read model + Redis counter design

## Interview Talking Points

- How do you calculate events/second in real time without hammering the database? (Redis INCR per time bucket)
- If one SignalR server crashes, do connected clients miss events? (Redis backplane ensures all servers receive the message; client reconnects to any server and replays)
- Why event sourcing for the event store instead of a regular table? (audit trail, replay, no data loss — events are facts, not state)
- How do you ensure the alert job doesn't fire duplicate alerts? (store last-alerted-at in Redis; skip if same rule triggered within cooldown period)
- How would you handle 1M events/day without the read model becoming a bottleneck? (batch projection updates, async projection via MassTransit consumer, snapshot at midnight)
