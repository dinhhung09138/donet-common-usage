# Lab: Advanced SQL

## Objectives

- Write advanced SQL queries using CTEs and window functions
- Understand index types and when to use covering indexes
- Read and interpret execution plans to identify bottlenecks

## Key Concepts

`CTE` · `ROW_NUMBER` · `RANK` · `DENSE_RANK` · `LAG/LEAD` · `PARTITION BY` · `Covering index` · `EXPLAIN / SET STATISTICS IO` · `Query hints` · `Filtered index`

## Tasks

- [ ] Rewrite a nested subquery as a CTE for readability and performance
- [ ] Implement pagination using `ROW_NUMBER() OVER (ORDER BY ...)` vs `OFFSET/FETCH`
- [ ] Use `LAG` / `LEAD` to compute running differences between rows
- [ ] Use `RANK` vs `DENSE_RANK` — demonstrate the gap behaviour
- [ ] Create a covering index and verify it eliminates a Key Lookup in the plan
- [ ] Read a SQL Server execution plan: identify Scans, Seeks, Lookups, and estimated vs actual rows
- [ ] Apply a query hint (`NOLOCK`, `FORCESEEK`) and document the trade-off
- [ ] Write a filtered index and a query that uses it

## Expected Output

A `.sql` script file per topic with annotated queries and a written comparison of before/after execution plans.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
