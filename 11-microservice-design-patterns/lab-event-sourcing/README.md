# Lab: Event Sourcing Pattern

## Objectives
- Persist an aggregate's state as an append-only sequence of domain events instead of current-state rows.
- Rebuild aggregate state by replaying its event stream, and implement snapshotting to bound replay cost for long streams.
- Handle event schema evolution (upcasting old event versions) without breaking existing streams.
- Combine event sourcing with CQRS by projecting the event stream into one or more read models.

## Key Concepts
`Event Sourcing` · `Event Store` · `Aggregate Replay` · `Snapshotting` · `Event Versioning/Upcasting` · `Projections`

## Tasks
- [ ] Model an aggregate (e.g., Order) whose state changes are captured as domain events (`OrderCreated`, `ItemAdded`, `OrderShipped`).
- [ ] Implement an append-only event store and a repository that rebuilds aggregate state by replaying its events.
- [ ] Add snapshotting so an aggregate with a long event history can be rehydrated from a snapshot + tail events instead of a full replay.
- [ ] Introduce a breaking change to an event's shape and implement an upcaster that transforms old event versions on read.
- [ ] Project the event stream into a read model (tie-in with [[lab-cqrs-pattern]]) and keep it updated as new events are appended.
- [ ] Verify state rebuilt from events matches state that would result from direct mutation, for a scripted sequence of operations.

## Expected Output
A working event-sourced aggregate where current state is always derivable by replaying its event stream, snapshotting measurably reduces rehydration time for a long stream, and an upcaster correctly handles a mixed-version event stream.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
