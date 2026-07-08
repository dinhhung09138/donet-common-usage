# Lab: CQRS Pattern

## Objectives

- Separate read and write models with CQRS using MediatR
- Use different database strategies for reads vs writes
- Add pipeline behaviors for cross-cutting concerns (validation, logging)

## Tasks

- [ ] Set up MediatR with dependency injection
- [ ] Create commands: `CreateOrderCommand`, `UpdateOrderCommand`, `DeleteOrderCommand`
- [ ] Create queries: `GetOrderByIdQuery`, `GetOrdersPagedQuery`
- [ ] Implement separate read model (optimized DTOs, no ORM overhead)
- [ ] Add pipeline behavior for FluentValidation (reject invalid commands before handler)
- [ ] Add pipeline behavior for logging (log all commands with timing)
- [ ] Add pipeline behavior for caching (cache read query results)
- [ ] Write tests: command handlers, query handlers, pipeline behaviors

## Expected Output

API using MediatR for all operations. Read/write models clearly separated. Pipeline behaviors applied.

## Key Concepts Practiced

`CQRS` · `MediatR` · `Pipeline behaviors` · `Read model` · `Write model`

## ADR

Write ADR: "Why CQRS for this service?" → `src/05-technical-english/design-docs/`

## Status

- [ ] Completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/`
- [ ] ADR written → `src/05-technical-english/design-docs/`
