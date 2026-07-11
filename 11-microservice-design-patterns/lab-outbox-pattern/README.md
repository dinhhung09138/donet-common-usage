# Lab: Outbox Pattern

## Objectives
- Guarantee atomicity between a database write and a message/event publish without a distributed transaction.
- Implement the transactional outbox: write the business change and the outgoing event to the same local database transaction.
- Build a relay process (polling publisher or CDC-based) that reads unpublished outbox rows and delivers them to a message broker.
- Handle at-least-once delivery and downstream idempotency so a relay crash or retry doesn't cause silent message loss or duplicate side effects.

## Key Concepts
`Outbox Pattern` · `Transactional Outbox` · `Polling Publisher` · `Change Data Capture (CDC)` · `At-Least-Once Delivery` · `Idempotent Consumer`

## Tasks
- [ ] Model a business operation (e.g., "create order") that must both persist a row and publish a domain event.
- [ ] Add an `Outbox` table written in the same local transaction as the business write, instead of publishing directly to a broker.
- [ ] Implement a relay (background polling worker, or a CDC connector like Debezium) that reads unpublished outbox rows and publishes them to a broker (e.g., RabbitMQ/Kafka/Service Bus).
- [ ] Mark rows as published (or delete them) only after a confirmed broker ack, and handle relay restarts without dropping or re-publishing indefinitely.
- [ ] Force a crash between the business write and the publish step, and verify the event is still eventually published after recovery.
- [ ] Implement an idempotent consumer on the receiving side (dedupe by event ID) to safely handle at-least-once redelivery.

## Expected Output
A demonstrated end-to-end flow where a business write and its corresponding event are never observed independently (no write without eventual publish, no publish without a committed write), including a forced-crash scenario that proves the event is still delivered after recovery.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
