# Lab: AutoMapper

## Objectives
- Author `Profile` classes that define explicit, testable entity-to-DTO and DTO-to-entity mappings instead of ad-hoc manual mapping code scattered across services.
- Configure custom member mappings, value resolvers, and type converters for cases where convention-based mapping is insufficient (flattening, computed fields, enum translation).
- Use `ProjectTo<T>` for EF Core `IQueryable` projection to push mapping into the SQL query instead of materializing full entities, a meaningful performance consideration at scale.
- Validate mapping configuration at startup (`AssertConfigurationIsValid`) so mapping mismatches fail fast in CI rather than surfacing as runtime bugs.

## Key Concepts
`Profile` · `CreateMap` · `ForMember` · `IValueResolver` · `ITypeConverter` · `ProjectTo<T>` · `IQueryable` projection · `AssertConfigurationIsValid` · Reverse mapping

## Tasks
- [ ] Define an entity model and corresponding read/write DTOs (e.g. `Order` entity vs. `OrderDto`/`CreateOrderDto`) with at least one field that doesn't map 1:1 by name.
- [ ] Author an AutoMapper `Profile` with `CreateMap` calls, using `ForMember` to resolve the non-trivial field (e.g. flattening `Customer.Name` into `OrderDto.CustomerName`).
- [ ] Implement a custom `IValueResolver` or `ITypeConverter` for a case requiring external logic (e.g. computing `OrderDto.TotalWithTax` from multiple entity fields).
- [ ] Use `ProjectTo<OrderDto>(configuration)` against an EF Core `IQueryable<Order>` and confirm (via logged SQL) that only the projected columns are selected.
- [ ] Register AutoMapper in DI (`AddAutoMapper`) and call `AssertConfigurationIsValid()` in a startup/unit test to catch unmapped or misconfigured members.
- [ ] Write unit tests for the mapping profile in isolation (not through a controller) covering the custom resolver and reverse mapping if used.

## Expected Output
A working .NET project with an AutoMapper profile mapping entities to DTOs, a `ProjectTo<T>` query against EF Core whose generated SQL selects only the mapped columns, a passing `AssertConfigurationIsValid()` check, and unit tests covering the custom value resolver.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
