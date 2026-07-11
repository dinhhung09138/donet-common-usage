# Lab: MongoDB Advanced (Transactions, Change Streams & Repository Pattern)

## Objectives

- Implement multi-document transactions for cross-collection consistency
- Consume change streams to react to data changes in real time
- Apply the repository pattern with MongoDB and understand its trade-offs

## Key Concepts

`Multi-document transactions` · `IClientSessionHandle` · `Change streams` · `ChangeStreamDocument<T>` · `IMongoRepository` · `Atlas Search` · `GridFS` · `Optimistic concurrency`

## Tasks

- [ ] Implement a transfer operation across two collections inside a `StartSession` / `StartTransaction` / `CommitTransaction` block
- [ ] Demonstrate rollback behaviour when one operation fails mid-transaction
- [ ] Open a change stream on a collection and log `Insert`, `Update`, `Delete` events to console
- [ ] Filter the change stream with a `$match` pipeline stage (e.g., only watch a specific `status` field)
- [ ] Build a generic `IMongoRepository<T>` with Find, Insert, Replace, Delete — register in DI
- [ ] Implement optimistic concurrency using a `Version` field updated with `$inc`
- [ ] Store and retrieve a binary file using GridFS (`IGridFSBucket`)
- [ ] (Optional) Run an Atlas Search query with a text index if a local Atlas instance is available

## Expected Output

A project demonstrating multi-document transactions (with failure rollback demo), a background change stream listener, and a repository abstraction with tests.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
