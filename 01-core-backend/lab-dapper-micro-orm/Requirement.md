# lab-dapper-micro-orm

## Objectives

- Understand when to choose Dapper over EF Core
- Write raw SQL with multi-mapping, stored procedures, and TVPs
- Manage connections and transactions manually

## Key Concepts

`Dapper` · `Multi-mapping` · `StoredProcedure` · `TVP` · `QueryMultiple` · `DynamicParameters` · `Connection management`

## Tasks

- [ ] Add Dapper to an ASP.NET Core project alongside EF Core
- [ ] Implement CRUD using `Query<T>` and `Execute`
- [ ] Use multi-mapping to hydrate parent-child relationships in one query
- [ ] Call a stored procedure with `DynamicParameters` and output params
- [ ] Pass a Table-Valued Parameter (TVP) for bulk insert
- [ ] Use `QueryMultiple` for a dashboard query (multiple result sets)
- [ ] Benchmark Dapper vs EF Core for the same query with BenchmarkDotNet

## Expected Output

A console/API project demonstrating each Dapper pattern with measurable performance comparisons against EF Core equivalents.
