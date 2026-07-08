# Lab: Event Sourcing

## Objectives

- Implement an append-only event store
- Rebuild aggregate state by replaying events
- Create projections (read models) from the event stream
- Implement snapshots for performance optimization

## Tasks

- [ ] Design event store schema (aggregate_id, version, event_type, payload, timestamp)
- [ ] Implement `EventStore` with append and load operations
- [ ] Create aggregate base class: apply events, track uncommitted events
- [ ] Implement `Account` aggregate: `AccountOpened`, `MoneyDeposited`, `MoneyWithdrawn`
- [ ] Implement optimistic concurrency (reject if version mismatch)
- [ ] Create projection: current account balance (updated on each event)
- [ ] Create projection: transaction history
- [ ] Implement snapshot: save state at every 50 events, load from snapshot + tail
- [ ] Write test: replay events → assert final state matches

## Expected Output

Event-sourced account domain. Demonstrate replay from scratch vs snapshot. Balance projection always consistent.

## Key Concepts Practiced

`Event sourcing` · `Append-only store` · `Projections` · `Snapshots` · `Optimistic concurrency`

## ADR

Write ADR: "When to use event sourcing — and when NOT to" → `src/05-technical-english/design-docs/`

## Status

- [ ] Completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/`
- [ ] ADR written → `src/05-technical-english/design-docs/`
