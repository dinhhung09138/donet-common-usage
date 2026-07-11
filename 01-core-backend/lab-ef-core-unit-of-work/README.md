# Lab: EF Core Unit of Work + Repository Pattern

## Objectives
- Design a Repository abstraction over EF Core `DbContext` that hides persistence details from application/service layers without leaking `IQueryable` in ways that break the abstraction.
- Implement a Unit of Work that coordinates multiple repositories under a single transaction boundary, matching how transactional consistency is handled in production multi-entity operations.
- Reason about when the Repository/Unit of Work pattern adds value on top of `DbContext` (already a Unit of Work/Repository) versus when it's redundant ceremony — an architect-level judgment call.
- Handle explicit transaction control (`BeginTransaction`/`Commit`/`Rollback`) and multi-repository save coordination, including failure/rollback scenarios.

## Key Concepts
`IRepository<T>` · `IUnitOfWork` · `DbContext.SaveChanges` · `IDbContextTransaction` · `BeginTransactionAsync` · Generic repository · Specification pattern (optional) · Transactional consistency

## Tasks
- [ ] Define a generic `IRepository<T>` interface (Add, Update, Remove, GetById, Find) and an EF Core implementation backed by `DbSet<T>`.
- [ ] Define an `IUnitOfWork` interface exposing repositories plus `SaveChangesAsync`, and implement it wrapping a single `DbContext` instance.
- [ ] Implement a multi-entity business operation (e.g. placing an order that decrements stock and creates an order record) that touches two repositories and commits atomically via the Unit of Work.
- [ ] Add explicit transaction handling for a scenario spanning more than one `SaveChangesAsync` call, and demonstrate a rollback path when a later step fails.
- [ ] Register repositories and the Unit of Work in DI with appropriate lifetimes (scoped) and wire them into a service layer.
- [ ] Write an integration test (e.g. against SQLite in-memory or a real SQL Server/PostgreSQL test container) proving the rollback scenario leaves no partial writes.

## Expected Output
A working .NET project with generic repository + Unit of Work implementations, a service method demonstrating a multi-repository transactional operation, and a passing integration test that verifies both the success path (all changes committed) and the failure path (all changes rolled back, no partial state).

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
