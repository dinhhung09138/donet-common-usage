# Capstone: Order Processing API

## Business Context

Build a production-grade e-commerce order lifecycle system: cart → payment → inventory deduction → fulfillment → notification. This is one of the most common system design questions at Arc.dev, Toptal, and fintech interviews.

## Prerequisite Labs

- `lab-ef-core-unit-of-work`
- `lab-masstransit-rabbitmq`
- `lab-stripe-payments`
- `lab-hangfire-advanced`
- `lab-email-sendgrid`
- `lab-signalr-hubs`
- `lab-polly-resilience`
- `lab-caching-patterns`
- `lab-oauth2-jwt` + `lab-rbac-implementation`

## Functional Requirements

- Customer places an order with multiple line items
- Payment is processed via Stripe PaymentIntent
- On successful payment, inventory is deducted and order enters fulfillment queue
- Customer receives real-time status updates (SignalR) and email confirmation (SendGrid)
- Admin can view all orders, cancel, and issue refunds
- Webhook endpoint receives Stripe payment events (charge.succeeded, payment_intent.payment_failed)

## Non-Functional Requirements

- Payment must be idempotent: re-submitting same order never results in double charge (idempotency key per order ID)
- Server crash between payment and inventory deduction must be recoverable (MassTransit Saga with outbox)
- Order status endpoint: < 100ms P99 (Redis cache with tag-based eviction on status change)
- Stripe webhook verified with HMAC-SHA256 before processing

## Architecture

```
POST /orders
  → validate (FluentValidation)
  → create Order (PENDING) in DB [EF Core UoW]
  → create Stripe PaymentIntent
  → publish OrderCreated event [MassTransit + outbox]

OrderCreated consumer:
  → deduct inventory
  → update Order (PAID)
  → publish OrderFulfillmentRequested

Fulfillment Hangfire job:
  → simulate fulfillment (or call 3PL API with Polly retry)
  → update Order (FULFILLED)
  → notify customer via SendGrid + SignalR

Stripe webhook:
  → verify HMAC signature
  → handle payment_intent.payment_failed → update Order (FAILED) + notify
```

## Implementation Steps

1. **Domain model:** `Order`, `OrderItem`, `OrderStatus` (enum), `Payment` entities with EF Core Fluent API
2. **Unit of Work:** wrap order creation + payment record in one transaction
3. **Stripe integration:** create PaymentIntent on order submit; store `paymentIntentId` on Order
4. **MassTransit Saga:** `OrderStateMachine` with states (Pending → Paid → Fulfilling → Fulfilled / Failed) — use EF Core saga persistence
5. **Outbox pattern:** configure MassTransit outbox so saga state + event publish are atomic
6. **Hangfire fulfillment job:** triggered by saga, calls external fulfillment API via Polly (retry + circuit breaker)
7. **SignalR hub:** `OrderStatusHub` — customer subscribes to their order group; saga publishes status changes via `IHubContext`
8. **Redis cache:** cache order summary by ID; evict on every status change
9. **Stripe webhook endpoint:** verify signature, dispatch to MassTransit consumer
10. **Auth:** JWT bearer — customers see own orders only; Admin role sees all (RBAC policy)
11. **Integration tests:** WebApplicationFactory + TestContainers (PostgreSQL + RabbitMQ) + Stripe test mode

## Expected Deliverables

- Working API with all endpoints documented in Swagger
- MassTransit saga state machine diagram (in README)
- At least 5 integration tests covering the happy path and payment failure scenario
- PR description explaining the saga + outbox design decision
- ADR: "Why MassTransit Saga over a simple event chain for order processing"

## Interview Talking Points

- How do you prevent a double charge if the server crashes after Stripe but before the DB write? (idempotency key + saga recovery)
- Why did you use a saga instead of simple event handlers? (compensating transactions, visible state)
- How does the outbox pattern guarantee the event is published even if the broker is temporarily down?
- What happens when Stripe sends a webhook twice? (idempotency by Stripe event ID)
- How would you scale this to 10,000 orders/minute? (read replicas, partitioned queues, cache-aside)
