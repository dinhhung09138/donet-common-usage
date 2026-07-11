# Lab: EF Core Interceptors

## Objectives
- Implement `SaveChangesInterceptor` to automate cross-cutting persistence concerns (audit fields, soft delete) without polluting domain/service code — a pattern expected in production multi-tenant systems.
- Implement `DbCommandInterceptor` to observe or modify generated SQL commands, e.g. for query logging or diagnostics.
- Distinguish interceptors from other EF Core cross-cutting mechanisms (global query filters, `SaveChanges` overrides, domain events) and justify which mechanism fits which concern.
- Wire interceptors into the DI-configured `DbContext` correctly, including interaction with `AddDbContext` and interceptor ordering.

## Key Concepts
`SaveChangesInterceptor` · `SavingChangesAsync` · `DbCommandInterceptor` · `ReaderExecutingAsync` · `ChangeTracker` · `EntityState` · Audit fields (`CreatedAt`/`ModifiedAt`/`CreatedBy`) · Soft delete · `AddInterceptors`

## Tasks
- [ ] Implement an `AuditingSaveChangesInterceptor` that stamps `CreatedAt`/`CreatedBy` on added entities and `ModifiedAt`/`ModifiedBy` on modified entities by inspecting `ChangeTracker.Entries()`.
- [ ] Implement a soft-delete interceptor that converts `EntityState.Deleted` into a flag update (`IsDeleted = true`) instead of a physical `DELETE`, and combine it with a global query filter so soft-deleted rows are excluded by default.
- [ ] Implement a `DbCommandInterceptor` (or use `ILogger`-based command logging) that logs generated SQL and parameter values for executed commands, useful for diagnosing production query issues.
- [ ] Register the interceptors via `optionsBuilder.AddInterceptors(...)` in `DbContext` configuration and confirm they fire for both `SaveChanges` and `SaveChangesAsync` call paths.
- [ ] Write a test proving an entity marked for deletion is not physically removed from the database but is excluded from default queries.
- [ ] Document the current-user resolution strategy used for `CreatedBy`/`ModifiedBy` (e.g. `IHttpContextAccessor`) and its testability trade-offs.

## Expected Output
A working .NET project where an auditing interceptor and a soft-delete interceptor are registered on the `DbContext`, a passing test suite showing audit fields populate automatically and deleted entities remain in the database but are filtered from queries, plus sample logged SQL output from the command interceptor.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
