# Lab: CQRS Pattern

## Objectives
- Separate the write model (commands) from the read model (queries) for a service with divergent read/write scaling needs.
- Implement a command handler pipeline that validates and persists writes to a normalized write store.
- Build a denormalized read model optimized for query patterns, kept in sync via domain events.
- Reason about the consistency window between a write and its visibility in the read model, and how to communicate that to API consumers.
- Justify when CQRS is worth the added complexity (genuinely divergent read/write scaling or modeling needs) vs. when a single model is simpler and sufficient.

## Key Concepts
`CQRS` · `Command Handler` · `Read Model` · `Write Model` · `Eventual Consistency` · `Projection`

## Tasks
- [ ] Define commands (e.g., `CreateOrder`, `UpdateOrderStatus`) and a write-side handler pipeline with validation.
- [ ] Persist writes to a normalized write store (e.g., relational tables).
- [ ] Build a denormalized read model (e.g., a single "order summary" document) optimized for the API's actual query shape.
- [ ] Implement a projector that consumes domain events from the write side and updates the read model asynchronously.
- [ ] Expose separate command and query endpoints, and measure/observe the replication lag between a write and its read-model update.
- [ ] Document the consistency guarantees exposed to API consumers (e.g., read-your-writes not guaranteed on the query endpoint).

## Expected Output
A service exposing distinct command and query APIs backed by separate write/read stores, with observable (logged) lag between a command being accepted and the corresponding read model being updated.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
