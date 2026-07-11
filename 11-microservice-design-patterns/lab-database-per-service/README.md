# Lab: Database per Service Pattern

## Objectives
- Enforce data ownership boundaries by giving each microservice its own private database/schema.
- Implement cross-service data access via API calls or events instead of direct cross-database joins/queries.
- Handle a business transaction that spans two services' databases using a saga (see [[lab-saga-pattern]]) instead of a distributed transaction.
- Explain the trade-offs (data duplication, eventual consistency, query complexity) introduced by per-service databases.

## Key Concepts
`Database per Service` · `Data Ownership` · `Bounded Context` · `Eventual Consistency` · `Anti-Corruption Layer`

## Tasks
- [ ] Stand up two services (e.g., Orders, Inventory), each with its own database instance/schema, with no shared tables or cross-database queries.
- [ ] Implement a read model in the Orders service that caches a denormalized copy of Inventory data it needs, kept in sync via events.
- [ ] Attempt (and reject) a naive cross-database join to demonstrate why it violates the pattern.
- [ ] Implement a cross-service business transaction (e.g., place order → reserve inventory) using an event-driven saga instead of a two-phase commit.
- [ ] Document which service is the system of record for each data entity.

## Expected Output
Two services with physically separate databases, a working event-driven read-model sync, and a documented saga flow proving the cross-service transaction completes consistently without a distributed transaction.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
