# Problem Lab: Sync-to-Async Migration — Order Service

> **Category:** Architecture Decision
> **Effort:** 2–3 days
> **Technologies:** MassTransit + Azure Service Bus, domain/integration event boundary, transactional outbox, CQRS write model, Polly timeout, TestContainers

---

## Scenario

An order service makes synchronous HTTP calls to 4 downstream services on every order creation: inventory (deduct stock), pricing (recalculate final price), email (send confirmation), and analytics (record event). P99 latency is 4.2 seconds — the slowest of the 4 services. A 5th service (fraud detection, 3-second SLA) is required by compliance within 30 days. Adding it synchronously would push P99 above 7 seconds. Every new downstream service requires modifying the order service code.

**Business impact:** Checkout conversion rate is dropping — UX research shows 60% of users abandon checkout after 3 seconds. Compliance requires fraud detection in 30 days. Engineering can't add new downstream services without touching the order service (team coupling).

---

## The Problem / Requirement

**Functional requirements:**
- Order creation response time < 500ms
- All downstream services (inventory, pricing, email, analytics, fraud) must still be executed
- Fraud detection result required before order is confirmed (cannot be fully async)
- Email and analytics can be eventually consistent (async OK)
- Adding a new downstream consumer must not require modifying the order service

**Non-functional requirements:**
- Eventual consistency acceptable for non-critical steps (email, analytics)
- Order must not be confirmed if fraud check fails
- All events idempotent — downstream can receive duplicate events safely

**Architecture decision to make:**
- Which downstream calls stay synchronous vs become async
- How to ensure the order record and the published event are atomic
- How to handle the fraud check (required, not optional) asynchronously

---

## Solution Design

**Option A — Keep all calls synchronous, optimize each:**
Reduces latency but doesn't eliminate coupling. Adding service 6 still requires order service change.

**Option B — Transactional outbox + fan-out pub/sub + synchronous fraud check only (recommended):**
Only fraud detection stays synchronous (required for order approval). All other downstream services become event-driven consumers. Order service publishes `OrderCreated` event via transactional outbox. Inventory, pricing, email, and analytics each subscribe independently — no order service changes needed to add a new subscriber.

**Why Option B:**
- Order endpoint: synchronous fraud check (3s) + DB write + event publish → returns ~500ms
- Email, analytics, inventory: async consumers, no longer in the critical path
- Adding service 6 = one new consumer class, zero order service changes
- Transactional outbox: `OrderCreated` event guaranteed to publish even if pod crashes after DB commit

```
Before:
  POST /orders
  → HTTP: inventory (800ms) → pricing (600ms) → email (1200ms) → analytics (300ms)
  P99: 4,200ms (slowest service in chain)

After:
  POST /orders
  ├── Fraud detection (synchronous, HTTP, 3s SLA via Polly timeout) ← required
  ├── DB write: Order record + outbox event (atomic)
  └── Return 202 Accepted { orderId } ← ~500ms

  [Async, order service unchanged]:
  ├── InventoryConsumer    ← subscribes to OrderCreated
  ├── PricingConsumer      ← subscribes to OrderCreated
  ├── EmailConsumer        ← subscribes to OrderCreated
  ├── AnalyticsConsumer    ← subscribes to OrderCreated
  └── [Future] FraudReviewConsumer ← zero changes to order service
```

---

## Implementation Tasks

1. **Define `OrderCreated` integration event and outbox pattern**
   - `OrderCreated`: OrderId, CustomerId, TenantId, LineItems, TotalAmount, CreatedAt
   - Outbox table: `OutboxMessage { Id, Type, Payload, PublishedAt, CreatedAt }`
   - DB write + outbox insert in one `BeginTransactionAsync` / `CommitAsync`
   - Acceptance: Pod crash after DB commit → on restart, outbox publisher sends `OrderCreated`; no duplicate if already sent (idempotent by MessageId)

2. **Implement `OutboxPublisher : BackgroundService`**
   - Poll unpublished outbox messages; publish via MassTransit; mark published
   - Handle duplicate publish attempts (MassTransit message dedup by MessageId)
   - Acceptance: Integration test — commit order + outbox → stop pod → restart → `OrderCreated` published exactly once

3. **Implement 4 async consumers on Azure Service Bus topic**
   - `InventoryConsumer`, `PricingConsumer`, `EmailConsumer`, `AnalyticsConsumer`
   - Each subscribes to `OrderCreated` via Azure Service Bus topic subscription
   - Each consumer idempotent (check if already processed this OrderId)
   - Acceptance: Publish `OrderCreated` once → all 4 consumers receive it (integration test with TestContainers RabbitMQ for local)

4. **Keep fraud detection synchronous with Polly timeout**
   - `FraudCheckService.CheckAsync(order)` — HTTP call to fraud service
   - Polly timeout: 3s hard limit; `TimeoutRejectedException` → return 422 Unprocessable Entity
   - Retry: 1× on 503; do not retry on 200-family or 4xx
   - Acceptance: Fraud service takes 4s → order rejected with 422 (Wiremock test)

5. **Add CQRS: separate write model from read model**
   - Write model: `Order` aggregate — minimal, focused on business rules
   - Read model: `OrderSummaryView` — updated by `OrderCreated` consumer (eventually consistent)
   - `GET /orders/{id}` reads from `OrderSummaryView`
   - Acceptance: `POST /orders` returns 202; `GET /orders/{id}` returns 404 for 500ms then 200 (eventual consistency demo)

6. **Integration test: full flow with TestContainers**
   - RabbitMQ + PostgreSQL via TestContainers
   - Test 1: Happy path — all 4 consumers receive event, order confirmed
   - Test 2: Fraud check timeout — order rejected, no event published, no consumers triggered
   - Test 3: Outbox recovery — commit + kill → restart → event published once
   - Acceptance: All 3 tests pass in CI without external services

---

## Acceptance Criteria

- [ ] `POST /orders` response time < 500ms (fraud check + DB write only in critical path)
- [ ] All 4 async consumers receive `OrderCreated` (integration test)
- [ ] Fraud timeout (> 3s) → 422 returned, no event published
- [ ] Outbox recovery: pod crash after commit → event published exactly once on restart
- [ ] Adding a 5th consumer requires zero changes to order service (architecture test)
- [ ] Read model eventually consistent: visible within 1s of order creation

---

## Interview Talking Points

**Situation:** Order creation P99 was 4.2s due to 4 synchronous downstream calls. Compliance required a 5th service (fraud) in 30 days. Adding it synchronously would push P99 above 7s. Every new service required modifying the order service.

**Task:** Redesign the order creation flow to stay under 500ms, satisfy the fraud detection requirement, and decouple downstream services from the order service.

**Action:**
- Identified that only fraud detection needed to be synchronous (required for order approval) — all other downstream services (inventory, email, analytics) could be eventually consistent
- Implemented transactional outbox to atomically commit the order record and the `OrderCreated` event — pod crashes after commit no longer cause lost events
- Migrated 4 downstream services to Azure Service Bus topic subscriptions — adding a new downstream consumer now requires zero changes to the order service

**Result:** P99 dropped from 4.2s to 380ms. Fraud detection added on time, within the 500ms budget. Three more consumers were added in the following 6 months by other teams, with zero order service changes.

**Follow-up questions to prepare:**
- "What happens if a consumer (e.g., inventory) fails to process the event?" → MassTransit retry → dead-letter after max retries. Order is confirmed but inventory deduction failed. This is an accepted trade-off: at-least-once delivery + consumer idempotency means retries are safe; manual reconciliation for dead-lettered events.
- "What if the fraud service is down at order creation time?" → Polly circuit breaker: after 5 failures, circuit opens and orders fail fast with 503. Operations team alerted via Application Insights. No orders accepted during fraud service outage — this is the business requirement.

---

## Key Concepts

`Transactional outbox` · `MassTransit` · `Azure Service Bus topic subscriptions` · `CQRS write/read model` · `Domain vs integration event` · `Polly timeout` · `Eventually consistent` · `Fan-out pub/sub` · `TestContainers`

---

## Status

- [ ] Completed
- [ ] PR description written (STAR format) → `PR-DESCRIPTION.md` in this lab folder
- [ ] ADR written → `ADR.md` in this lab folder
- [ ] Added to real-world-cases → `technical-interview/real-world-cases/`
