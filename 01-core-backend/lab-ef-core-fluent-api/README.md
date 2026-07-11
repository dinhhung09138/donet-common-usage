# Lab: EF Core Fluent API Configuration

## Objectives
- Configure entity mappings using `IEntityTypeConfiguration<T>` instead of scattering configuration across `OnModelCreating`, in line with how production EF Core codebases stay maintainable at scale.
- Model one-to-many, many-to-many, and owned-entity relationships explicitly via Fluent API, including shadow foreign keys and cascade behavior.
- Design indexes (including composite and filtered/unique indexes) that reflect real query patterns rather than defaults.
- Apply value converters and comparers to map complex/custom types (e.g. enums stored as strings, value objects, encrypted fields) to relational columns.
- Reason about when Fluent API is required over Data Annotations (e.g. composite keys, table splitting, query filters) as an architect evaluating trade-offs.

## Key Concepts
`IEntityTypeConfiguration<T>` · `ModelBuilder` · `HasOne`/`WithMany` · `HasForeignKey` · `OwnsOne` · `HasIndex` · `IsUnique` · `HasFilter` · `ValueConverter` · `ValueComparer` · `HasQueryFilter` · `ApplyConfigurationsFromAssembly`

## Tasks
- [ ] Create a domain model (e.g. `Order`, `Customer`, `OrderLine`, `Address`) with at least one one-to-many and one owned-entity relationship.
- [ ] Implement a separate `IEntityTypeConfiguration<T>` class per entity and register them all via `ApplyConfigurationsFromAssembly` in `OnModelCreating`.
- [ ] Configure explicit relationships (foreign keys, delete behavior, required/optional navigation) instead of relying on EF Core convention-based discovery.
- [ ] Add a composite unique index and a filtered index (e.g. unique email where `IsDeleted = false`) and verify the generated SQL/migration.
- [ ] Implement a `ValueConverter` (e.g. enum-to-string or a `Money` value object to `decimal`) with a matching `ValueComparer` where change tracking correctness matters.
- [ ] Add a global query filter (e.g. soft-delete) and demonstrate it can be bypassed with `IgnoreQueryFilters()`.
- [ ] Generate an EF Core migration and inspect the resulting SQL to confirm the configuration produced the intended schema.

## Expected Output
A working .NET project with a `DbContext`, per-entity `IEntityTypeConfiguration<T>` classes, at least one generated migration whose SQL script shows the composite/filtered indexes and converted column types, and a short console/test output demonstrating the query filter and value conversion behave as configured.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
