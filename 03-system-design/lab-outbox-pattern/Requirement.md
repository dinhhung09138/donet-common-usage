# Lab: Outbox Pattern

## Objectives

- Guarantee reliable event publishing alongside database writes (no lost messages)
- Implement the transactional outbox pattern without a framework
- Understand at-least-once delivery and build idempotent consumers

## Problem

Without outbox: save to DB succeeds, message publish fails → data inconsistency.

## Tasks

- [ ] Create `OutboxMessage` table: id, occurred_on, type, payload, processed_on
- [ ] Modify domain operations: save entity + outbox message in the **same transaction**
- [ ] Implement outbox processor: background service polls unprocessed messages
- [ ] Processor publishes message to Service Bus, marks as processed
- [ ] Handle processor failure: messages stay unprocessed, retry on next poll
- [ ] Implement idempotent consumer on the subscriber side (deduplicate by message id)
- [ ] Add unit test: simulate DB save success + publish failure → verify message not lost
- [ ] Measure: outbox polling interval vs latency trade-off

## Expected Output

Domain service + outbox table + background processor. Failure injection test showing no message loss.

## Key Concepts Practiced

`Outbox pattern` · `Transactional consistency` · `At-least-once delivery` · `Idempotency` · `Background service`

## Status

- [ ] Completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/`
- [ ] ADR written → `src/05-technical-english/design-docs/`
