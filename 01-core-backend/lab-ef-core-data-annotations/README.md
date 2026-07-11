# Lab: EF Core Data Annotations

## Objectives
- Configure entity-to-table mapping and column constraints using Data Annotation attributes (`[Table]`, `[Column]`, `[Key]`, `[Required]`, `[MaxLength]`, `[ConcurrencyCheck]`, etc.).
- Apply validation attributes that participate in both EF Core model building and ASP.NET Core model validation, understanding the dual role they play.
- Identify the boundary where Data Annotations stop being sufficient and Fluent API becomes necessary (composite keys, complex relationships, conditional indexes).
- Make an informed, documented trade-off decision between Data Annotations and Fluent API for a given schema, as expected in an architecture review.

## Key Concepts
`[Table]` · `[Column]` · `[Key]` · `[Required]` · `[MaxLength]`/`[StringLength]` · `[ConcurrencyCheck]`/`[Timestamp]` · `[ForeignKey]` · `[NotMapped]` · `[Index]` · Convention-based configuration precedence

## Tasks
- [ ] Reuse (or recreate) the domain model from `lab-ef-core-fluent-api` and re-express its mapping purely with Data Annotation attributes on the entity classes.
- [ ] Configure required fields, max lengths, and a concurrency token (`[Timestamp]` or `[ConcurrencyCheck]`) via attributes.
- [ ] Configure a foreign key relationship using `[ForeignKey]` and confirm it produces the same schema as the Fluent API equivalent.
- [ ] Attempt to express a scenario Data Annotations cannot cleanly handle (e.g. a composite index, a filtered unique index, or table splitting) and document why Fluent API is required.
- [ ] Generate a migration from the annotation-based model and diff the resulting SQL against the Fluent API lab's migration for equivalent entities.
- [ ] Write a short comparison note (in the README's Implementation Walkthrough, once filled in) on precedence rules when both Data Annotations and Fluent API configure the same property.

## Expected Output
A working .NET project whose entities are configured entirely through Data Annotations, a generated migration whose SQL is functionally equivalent to the Fluent API lab for the shared parts of the schema, and a documented list of the specific configuration needs that forced a fallback to Fluent API.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
