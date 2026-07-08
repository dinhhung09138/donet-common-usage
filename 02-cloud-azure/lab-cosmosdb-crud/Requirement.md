# Lab: CosmosDB CRUD + Partition Strategy

## Objectives

- Implement CRUD operations using the CosmosDB .NET SDK v3
- Design and test partition key strategies
- Understand RU/s consumption and how to minimize cross-partition queries

## Tasks

- [ ] Create CosmosDB account (free tier) with a container
- [ ] Implement repository pattern with CosmosDB SDK v3
- [ ] Design two partition key options and compare query costs in RU/s
- [ ] Implement point reads (most efficient — id + partition key)
- [ ] Implement cross-partition queries and show RU/s cost
- [ ] Implement optimistic concurrency with ETags
- [ ] Add TTL (time-to-live) for automatic document expiration
- [ ] Use managed identity for auth (no keys)

## Expected Output

Working CRUD app with RU/s cost comparison documented in README. Good vs bad partition key design side-by-side.

## Key Concepts Practiced

`CosmosDB SDK` · `Partition key` · `RU/s` · `Point read` · `ETags` · `TTL`

## Status

- [ ] Completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/`
