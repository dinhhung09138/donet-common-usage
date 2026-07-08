# Problem Lab: Monolith Strangler Fig — Extracting the Order Module

> **Category:** Architecture Decision
> **Effort:** 2–3 days
> **Technologies:** YARP reverse proxy, MassTransit integration events, transactional outbox, EF Core bounded contexts, Azure App Config feature flags, NetArchTest, PactNet

---

## Scenario

A 6-year-old .NET Framework 4.8 monolith handles orders, inventory, invoicing, and reporting in one 400,000-line codebase. Two teams of 6 developers each are constantly blocking each other — merge conflicts on shared entities, broken deployments from unrelated changes, inability to scale the order service independently. An investor requires the Order module to be independently deployable within 3 months as a condition for next funding round.

**Business impact:** Funding conditional on Order module extraction. Two teams blocked by merge conflicts weekly. Order service must scale independently for Black Friday — impossible in the monolith (monolith scales as a whole unit).

---

## The Problem / Requirement

**Functional requirements:**
- Order functionality extracted to a new .NET 8 microservice (`OrderService`)
- During transition: both monolith and new service can handle orders (dual-write phase)
- After transition: monolith delegates all Order requests to new service transparently (clients see no change)
- Rollback: if the new service has issues, traffic can be redirected back to monolith in < 5 minutes

**Non-functional requirements:**
- Zero downtime migration: clients (web, mobile, APIs) must not change their URLs
- Both monolith and new service kept in sync during dual-write phase
- Architecture boundaries enforced after extraction (new service cannot import monolith code)

**Architecture decision to make:**
- How to route traffic without changing client URLs (Strangler Fig proxy)
- How to keep data in sync during dual-write phase (transactional outbox + integration events)
- How to enforce new boundaries and prevent re-coupling

---

## Solution Design

**Option A — Big Bang rewrite:**
Rewrite order module in isolation. No shared code. High risk — monolith and new service diverge during development. Requires feature freeze on order module for 3 months.

**Option B — Strangler Fig with YARP reverse proxy + feature flag traffic migration (recommended):**
YARP proxy sits in front of both monolith and new service. Feature flag controls what percentage of traffic routes to new service. Both services write to their own databases during dual-write phase. Integration events keep data in sync. PactNet contract tests prevent re-coupling. NetArchTest enforces new service boundaries.

**Why Option B:**
- Zero client change: same URL, proxy handles routing transparently
- Low risk: start at 0% traffic to new service, ramp gradually
- Rollback: change feature flag to 0% → all traffic back to monolith in < 1 minute
- Dual-write safety: neither service depends on the other's DB

```
Client: POST /orders (unchanged URL)
    │
    ▼
YARP Reverse Proxy (ASP.NET Core)
    │ Feature flag: "OrderServiceTraffic" = 0% → 10% → 50% → 100%
    │
    ├── 0%:   ALL → Monolith (/orders)
    ├── 10%:  10% → OrderService, 90% → Monolith
    └── 100%: ALL → OrderService (/orders)

Dual-write phase (feature flag 10–99%):
    Monolith writes order → publishes OrderCreated (outbox)
        ↓
    OrderService subscribes → syncs read model
    (and vice versa for changes originating in OrderService)
```

---

## Implementation Tasks

1. **Set up YARP reverse proxy with feature flag routing**
   - YARP: `AddReverseProxy()` with two clusters: `monolith` and `order-service`
   - Custom `ITransformProvider`: check `IFeatureManager.IsEnabledAsync("OrderServiceTraffic")` per request
   - Azure App Config feature flag with percentage rollout for `OrderServiceTraffic`
   - Acceptance: 0% → all requests hit monolith; 100% → all hit order service (verify with request log)

2. **Extract Order bounded context: new EF Core `OrderDbContext`**
   - New `OrderDbContext` with only `Order`, `OrderLine`, `OrderStatus` entities
   - No shared entities with monolith's `InventoryDbContext` or `InvoiceDbContext`
   - Acceptance: NetArchTest rule: `OrderService` project has zero EF entity references from monolith assemblies

3. **Implement integration events for dual-write sync**
   - Monolith publishes `OrderCreatedInMonolith` event via outbox on every order write
   - `OrderService` subscribes: if order not yet in its DB → import; if already exists → skip (idempotent)
   - OrderService publishes `OrderCreatedInOrderService` → monolith subscribes for inverse sync
   - Acceptance: Create order in monolith → within 5s order exists in OrderService DB (integration test)

4. **Implement rollback mechanism**
   - `OrderServiceTraffic` feature flag set to 0% → all traffic routes back to monolith
   - Acceptance: Change flag to 0% in Azure App Config → YARP routes 100% to monolith within 30s (sentinel key refresh)

5. **PactNet consumer contract tests between proxy and both services**
   - Define Pact: proxy (consumer) expects `POST /orders` to return `{ orderId, status, estimatedDelivery }`
   - Run PactVerifier against both monolith and order service
   - Acceptance: Both services satisfy the same contract; any schema divergence fails CI

6. **NetArchTest enforcement of new service boundaries**
   - Rule: `OrderService` assembly must not reference any type from `MonolithApp` assembly
   - Rule: `OrderService` must not contain direct SQL to the monolith's database connection string
   - Acceptance: Architecture test suite fails if coupling is introduced

7. **Traffic ramp plan and runbook**
   - Document: 0% → 1% (1 day) → 10% (3 days) → 50% (1 week) → 100% (2 weeks)
   - Acceptance criteria per stage: error rate < 0.1%, P99 < existing monolith P99, dual-write sync lag < 5s
   - Rollback procedure: single Azure App Config change, < 5 minutes

---

## Acceptance Criteria

- [ ] Client URL unchanged; YARP routes correctly at 0%, 10%, 100% (integration test per percentage)
- [ ] 0% → monolith; 100% → order service (verified by request logs)
- [ ] Rollback in < 5 minutes: change flag to 0% → all traffic back to monolith
- [ ] Dual-write sync: create order in monolith → exists in OrderService within 5s
- [ ] PactNet: both services satisfy same contract (CI test)
- [ ] NetArchTest: OrderService has zero references to monolith assemblies

---

## Interview Talking Points

**Situation:** 400k-line .NET 4.8 monolith. Two teams blocking each other weekly on merge conflicts. Investor required Order module independently deployable in 3 months.

**Task:** Extract the Order module to a new .NET 8 microservice without downtime and with a safe rollback plan.

**Action:**
- Used YARP reverse proxy as the Strangler Fig layer — client URLs unchanged, proxy decides where to route each request based on an Azure App Config feature flag percentage rollout
- Implemented transactional outbox on both sides of the dual-write phase so that neither service depends on the other's DB for correctness — sync is eventual but durable
- Added NetArchTest rules and PactNet contract tests to enforce the new boundary structurally — making it impossible for future developers to accidentally re-couple the services

**Result:** Order service fully extracted in 10 weeks (under the 3-month requirement). Funding round closed. Teams now deploy their services independently, 2–3 times per week each, with zero merge conflicts between them.

**Follow-up questions to prepare:**
- "How did you handle data that existed in the monolith's Order table before the extraction?" → One-time migration: Hangfire batch job reads all historical orders from monolith DB and inserts into OrderService DB with the same IDs. Idempotent — safe to re-run. Completed before ramping traffic above 0%.
- "What if the monolith's order creation starts failing during the dual-write phase?" → Circuit breaker on the monolith's integration event consumer in OrderService: if monolith events stop arriving, OrderService marks those orders for manual reconciliation rather than failing silently.

---

## Key Concepts

`Strangler Fig pattern` · `YARP reverse proxy` · `Feature flag traffic migration` · `Transactional outbox` · `EF Core bounded context` · `Integration events` · `Dual-write` · `PactNet contract tests` · `NetArchTest` · `Azure App Configuration`

---

## Status

- [ ] Completed
- [ ] PR description written (STAR format) → `PR-DESCRIPTION.md` in this lab folder
- [ ] ADR written → `ADR.md` in this lab folder
- [ ] Added to real-world-cases → `technical-interview/real-world-cases/`
