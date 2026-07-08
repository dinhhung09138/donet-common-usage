# Lab: Saga Pattern

## Objectives

- Implement a multi-step distributed transaction using the saga pattern
- Compare choreography (event-driven) vs orchestration (state machine) approaches
- Implement compensating transactions for rollback

## Scenario

Order placement saga: Reserve inventory → Charge payment → Ship order. Any step failure triggers compensation.

## Tasks

### Choreography (event-driven)
- [ ] Services communicate via events (Service Bus)
- [ ] `OrderService` publishes `OrderCreated`
- [ ] `InventoryService` listens → reserves → publishes `InventoryReserved` or `InventoryFailed`
- [ ] `PaymentService` listens → charges → publishes `PaymentCharged` or `PaymentFailed`
- [ ] On failure: publish compensating events (`ReleaseInventory`, `RefundPayment`)

### Orchestration (state machine)
- [ ] `OrderSagaOrchestrator` drives the flow
- [ ] Uses MassTransit Saga state machine or custom state store
- [ ] Explicit state transitions: `PendingInventory` → `PendingPayment` → `Completed`
- [ ] Orchestrator issues compensating commands on failure

### Comparison
- [ ] Document: choreography vs orchestration trade-offs in a design doc

## Expected Output

Both implementations running side by side. Failure scenario demo showing compensation. Design doc comparing approaches.

## Key Concepts Practiced

`Saga` · `Choreography` · `Orchestration` · `Compensating transactions` · `State machine`

## Status

- [ ] Completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/`
- [ ] ADR written → `src/05-technical-english/design-docs/`
