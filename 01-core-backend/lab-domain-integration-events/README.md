# Lab: Domain Events vs Integration Events (Outbox-Lite)

## Objectives

- Distinguish domain events (in-process, same transaction) from integration events (cross-service, eventually consistent)
- Raise domain events from aggregate roots without leaking infrastructure concerns into the domain model
- Dispatch domain events reliably after `SaveChanges` succeeds, not before
- Implement an outbox-lite pattern to guarantee at-least-once delivery of integration events without a full outbox framework
- Reason about failure windows (crash after commit, before publish) and how the outbox closes them

## Key Concepts

`Domain event` · `Integration event` · `Aggregate root` · `IDomainEvent` · `MediatR notification` · `SaveChanges interceptor` · `Outbox pattern` · `Outbox table` · `At-least-once delivery` · `Eventual consistency` · `Idempotent consumer`

## Tasks

- [ ] Define an `IDomainEvent` marker and raise events from an aggregate root (e.g., `Order.Place()` raises `OrderPlacedDomainEvent`)
- [ ] Collect raised domain events on the aggregate and dispatch them in-process via MediatR after `SaveChangesAsync` commits, using an `SaveChangesInterceptor` or a unit-of-work wrapper
- [ ] Show why dispatching before `SaveChangesAsync` is wrong — demonstrate a handler observing state that was later rolled back
- [ ] Design an `OutboxMessage` table (id, type, payload, occurred_on, processed_on) and write outbox rows in the same transaction as the aggregate change
- [ ] Implement a background dispatcher (hosted service) that polls the outbox, publishes unprocessed messages as integration events, and marks them processed
- [ ] Map a domain event to its corresponding integration event (e.g., `OrderPlacedDomainEvent` → `OrderPlacedIntegrationEvent`) with an explicit translation step
- [ ] Simulate a crash between commit and publish; verify the outbox dispatcher still delivers the message on next poll (at-least-once)
- [ ] Make the downstream consumer idempotent so redelivery from the outbox doesn't cause duplicate side effects
- [ ] Write an integration test proving: aggregate change + outbox row are committed atomically, and the dispatcher eventually publishes

## Expected Output

An ASP.NET Core service where placing an order commits the aggregate change and an outbox row in one transaction, an in-process domain event handler reacts synchronously after commit, and a background dispatcher reliably publishes the integration event even if the process restarts before the first publish attempt.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
