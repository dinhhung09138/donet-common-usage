# Problem Lab: Microservice Order Fulfillment with Compensating Transactions

> **Category:** Feature Building
> **Effort:** 2–3 days
> **Technologies:** MassTransit Saga, compensating transactions, transactional outbox, Azure Service Bus topics, CQRS, TestContainers

---

## Scenario

An e-commerce platform needs order fulfillment split across 3 microservices: Inventory (deducts stock), Shipping (creates shipment), and Notification (sends confirmation email). Each service has its own database. There are no distributed transactions. If inventory succeeds but shipping fails (carrier API down), the inventory deduction must roll back — the order must never be in a partially fulfilled state visible to the customer.

**Business impact:** Without compensating transactions, failed orders leave inventory permanently deducted, causing stock discrepancies that require manual reconciliation every day. Customer support receives "my order failed but the item went out of stock" complaints weekly.

---

## The Problem / Requirement

**Functional requirements:**
- On order placed: deduct inventory → create shipment → send email confirmation
- If shipping creation fails: compensate by restoring inventory
- If notification fails: do NOT roll back (non-critical) — log and continue
- Order status visible at each step: `Pending → InventoryReserved → ShipmentCreated → Confirmed`

**Non-functional requirements:**
- Each step idempotent: replay-safe if message is redelivered
- Observable: each state transition logged with correlation ID
- Testable with TestContainers (no real Azure Service Bus in tests)

**Edge cases:**
- Shipping service temporarily unavailable (503) — retry 3× then compensate
- Duplicate `OrderPlaced` message — saga must detect already-processed orders (idempotency)
- Compensation itself fails (inventory service down during rollback) — log + alert, do not loop forever

---

## Solution Design

**Option A — Choreography (each service reacts to events):**
Inventory publishes `InventoryReserved`, Shipping subscribes and publishes `ShipmentCreated`, etc. No central coordinator — but: hard to reason about failure paths, no clear compensation logic when chained events fail mid-flow.

**Option B — Orchestration Saga with MassTransit (recommended):**
A central `OrderFulfillmentSaga` state machine coordinates the steps. It knows the current state, what to do next, and what to compensate if a step fails. MassTransit handles retry, dead-letter, and state persistence.

**Why Option B:**
- Compensation logic explicit and centralized — easy to add new steps
- Saga state persisted in DB — survives pod restart mid-flow
- MassTransit handles retry + dead-letter per step independently

```
OrderPlaced event
    │
    ▼
OrderFulfillmentSaga (state: Pending)
    │
    ├──► ReserveInventoryCommand ──► InventoryService
    │         │
    │    InventoryReserved / InventoryFailed
    │         │
    ├──── OK: CreateShipmentCommand ──► ShippingService
    │         │
    │    ShipmentCreated / ShipmentFailed
    │         │
    │    FAIL: ReleaseInventoryCommand ──► InventoryService (compensate)
    │
    └──── OK: SendOrderConfirmationCommand ──► NotificationService (non-critical)
```

---

## Implementation Tasks

1. **Define saga state machine: `OrderFulfillmentSaga`**
   - States: `Pending`, `InventoryReserved`, `ShipmentCreated`, `Confirmed`, `Failed`
   - Events: `OrderPlaced`, `InventoryReserved`, `InventoryFailed`, `ShipmentCreated`, `ShipmentFailed`, `NotificationSent`
   - Compensating transition: `ShipmentFailed` → publish `ReleaseInventoryCommand` → state = `Failed`
   - Acceptance: Unit test each state transition with MassTransit test harness

2. **Implement InventoryService consumer**
   - `ReserveInventoryCommand` → deduct stock, publish `InventoryReserved` or `InventoryFailed`
   - `ReleaseInventoryCommand` → restore stock (compensation), idempotent (no double-restore)
   - Acceptance: Test idempotency — send `ReleaseInventoryCommand` twice, stock restored only once

3. **Implement ShippingService consumer**
   - `CreateShipmentCommand` → call carrier API (simulate with Wiremock), publish `ShipmentCreated` or `ShipmentFailed`
   - UseMessageRetry: 3 attempts, exponential backoff; `ShipmentFailed` published after exhausting retries
   - Acceptance: Wiremock stub returns 503 × 3 → `ShipmentFailed` published, saga triggers compensation

4. **Implement NotificationService consumer**
   - `SendOrderConfirmationCommand` → send email via SendGrid (non-critical: UseMessageRetry, no compensation on failure)
   - Acceptance: Notification failure does NOT trigger saga compensation; order remains `Confirmed`

5. **Persist saga state with EF Core saga repository**
   - `AddSagaStateMachine<OrderFulfillmentSaga, OrderFulfillmentState>().EntityFrameworkRepository()`
   - Acceptance: Stop pod during `InventoryReserved` state, restart, verify saga resumes from correct state

6. **Add correlation ID tracing across all consumers**
   - Pass `CorrelationId` from `OrderPlaced` through all commands/events
   - Enrich Serilog `LogContext` with `CorrelationId` in each consumer
   - Acceptance: Single order trace shows all steps in Application Insights grouped by CorrelationId

7. **Integration test: full saga flow with TestContainers**
   - RabbitMQ + PostgreSQL via TestContainers
   - Test 1: Happy path — all steps succeed, order reaches `Confirmed`
   - Test 2: Shipping fails after retry — compensation runs, inventory restored, order in `Failed`
   - Acceptance: Both tests pass in CI without external services

---

## Acceptance Criteria

- [ ] Happy path: `OrderPlaced` → `Confirmed` state in < 5s (integration test)
- [ ] Shipping failure triggers compensation: inventory restored within saga timeout (integration test)
- [ ] Notification failure: order remains `Confirmed` (compensation not triggered)
- [ ] Duplicate `OrderPlaced` message: saga processes once (idempotency via CorrelationId)
- [ ] Pod restart during `InventoryReserved`: saga resumes correctly from persisted state
- [ ] All traces show CorrelationId across all 3 service logs
- [ ] Full integration test with TestContainers passes in CI

---

## Interview Talking Points

**Situation:** Order fulfillment needed to span 3 separate microservices with their own databases. A failed shipment creation was leaving inventory permanently deducted, causing daily stock reconciliation work.

**Task:** Design a distributed fulfillment flow with automatic compensation — if any step fails, previously completed steps must roll back.

**Action:**
- Chose orchestration saga over choreography because compensation logic needed to be explicit and centralized — with choreography, it was impossible to reason about what should happen when a mid-chain event failed
- Implemented `OrderFulfillmentSaga` state machine with MassTransit, persisting state to PostgreSQL so the saga survives pod restarts mid-flow
- Made compensation idempotent by including the original `OrderId` in `ReleaseInventoryCommand` and checking if stock was already restored — preventing double-restore from message redelivery

**Result:** Zero stock discrepancies in the two months after launch. Adding a new fulfillment step (fraud check) took 4 hours — a new state, two new events, zero changes to existing consumers.

**Follow-up questions to prepare:**
- "What happens if the compensation itself fails?" → Saga moves to a `CompensationFailed` terminal state and sends alert via dead-letter queue; requires manual intervention — this is acceptable because it's a rare infrastructure failure, not a normal business error
- "Why not use a distributed transaction (2PC)?" → 2PC requires all services to lock resources simultaneously — with 3 microservices it creates cascading lock contention and is fragile across network boundaries; saga with compensation is more resilient

---

## Key Concepts

`MassTransit Saga` · `State machine` · `Compensating transactions` · `Transactional outbox` · `Azure Service Bus topics` · `CQRS` · `EF Core saga repository` · `TestContainers` · `Idempotency`

---

## Status

- [ ] Completed
- [ ] PR description written (STAR format) → `PR-DESCRIPTION.md` in this lab folder
- [ ] ADR written → `ADR.md` in this lab folder
- [ ] Added to real-world-cases → `technical-interview/real-world-cases/`
