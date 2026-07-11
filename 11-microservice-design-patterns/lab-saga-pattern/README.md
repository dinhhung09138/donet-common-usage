# Lab: Saga Pattern

## Objectives
- Coordinate a business transaction across multiple microservices using the Saga pattern instead of a distributed (2PC) transaction.
- Implement both choreography (event-driven) and orchestration (central coordinator) saga styles for the same workflow, and compare them.
- Design compensating actions for each step so a mid-saga failure can be rolled back safely.
- Handle saga state persistence and idempotent step execution so a step can be safely retried after a crash.

## Key Concepts
`Saga Pattern` · `Choreography` · `Orchestration` · `Compensating Transaction` · `Idempotency` · `Distributed Transaction` · `MassTransit` · `Temporal`

## Tasks
- [ ] Model a multi-step business transaction spanning 3 services (e.g., Order → Payment → Inventory).
- [ ] Implement the workflow as a choreography saga: each service publishes/subscribes to domain events and reacts independently.
- [ ] Implement the same workflow as an orchestration saga: a central saga orchestrator issues commands and tracks state.
- [ ] Add a compensating action for each step (e.g., refund payment, release inventory) and trigger it when a downstream step fails.
- [ ] Persist saga state so an in-flight saga can resume after the orchestrator restarts.
- [ ] Force a mid-saga failure and verify the system converges to a consistent state via compensations.

## Expected Output
Two working implementations (choreography and orchestration) of the same cross-service transaction, with a demonstrated failure injection that triggers compensating actions and leaves the system in a consistent end state.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
