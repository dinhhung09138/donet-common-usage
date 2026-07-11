# Lab: SQL Transactions & Isolation Levels

## Objectives

- Understand the difference between implicit and explicit transactions in EF Core and Dapper
- Master the 5 SQL Server isolation levels and the anomalies each prevents
- Implement `TransactionScope` correctly with async/await
- Handle deadlocks at the application layer with retry logic
- Use savepoints for partial rollback within a single transaction

## Key Concepts

`BeginTransactionAsync` · `IDbContextTransaction` · `TransactionScope` · `IsolationLevel` · `READ COMMITTED` · `REPEATABLE READ` · `SERIALIZABLE` · `SNAPSHOT` · `Savepoint` · `Deadlock` · `1205 error` · `Exponential backoff` · `Ambient transaction` · `Dapper transaction`

## Tasks

- [ ] Run two concurrent EF Core updates without an explicit transaction — observe a partial-write scenario
- [ ] Wrap the same operations in `BeginTransactionAsync` + `CommitAsync` / `RollbackAsync` — verify atomicity
- [ ] Demonstrate each isolation level using two concurrent connections: show dirty read (READ UNCOMMITTED), non-repeatable read, and phantom read
- [ ] Enable SNAPSHOT isolation on a SQL Server database and compare throughput vs SERIALIZABLE under concurrent load
- [ ] Implement `TransactionScope` with `TransactionScopeAsyncFlowOption.Enabled` — demonstrate why omitting `AsyncFlowOption` causes ambient transaction loss in async code
- [ ] Create a savepoint mid-transaction, perform a partial failure, roll back to the savepoint only, then commit the rest
- [ ] Simulate a deadlock between two transactions; catch error 1205 and implement exponential-backoff retry (3 attempts, jitter)
- [ ] Share a single `IDbTransaction` between EF Core and Dapper in the same unit of work

## Expected Output

A console or xUnit project with one test/demo per task, each printing the before/after state and confirming the expected behaviour (atomicity, isolation, retry success).

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
