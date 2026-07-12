# Lab: Advanced SQL

## Objectives

- Write advanced SQL queries using CTEs and window functions
- Understand index types and when to use covering indexes
- Read and interpret execution plans to identify bottlenecks

## Key Concepts

`CTE` · `ROW_NUMBER` · `RANK` · `DENSE_RANK` · `LAG/LEAD` · `PARTITION BY` · `Covering index` · `EXPLAIN / SET STATISTICS IO` · `Query hints` · `Filtered index`

## Tasks

- [x] Rewrite a nested subquery as a CTE for readability and performance
- [x] Implement pagination using `ROW_NUMBER() OVER (ORDER BY ...)` vs `OFFSET/FETCH`
- [x] Use `LAG` / `LEAD` to compute running differences between rows
- [x] Use `RANK` vs `DENSE_RANK` — demonstrate the gap behaviour
- [x] Create a covering index and verify it eliminates a Key Lookup in the plan
- [x] Read a SQL Server execution plan: identify Scans, Seeks, Lookups, and estimated vs actual rows
- [x] Apply a query hint (`NOLOCK`, `FORCESEEK`) and document the trade-off
- [x] Write a filtered index and a query that uses it

## Expected Output

A `.sql` script file per topic with annotated queries and a written comparison of before/after execution plans.

Delivered as [`scripts/`](scripts/) — one annotated T-SQL file per topic, plus a shared schema/seed script:

| File | Topic |
| ---- | ----- |
| [`00-schema-and-seed.sql`](scripts/00-schema-and-seed.sql) | Shared `Customers` / `Orders` / `OrderItems` schema + ~5k/200k/500k row seed (run first) |
| [`01-cte-vs-subquery.sql`](scripts/01-cte-vs-subquery.sql) | Nested subquery rewritten as a CTE |
| [`02-pagination-row-number-vs-offset.sql`](scripts/02-pagination-row-number-vs-offset.sql) | `ROW_NUMBER()` vs `OFFSET/FETCH` pagination |
| [`03-lag-lead-running-diff.sql`](scripts/03-lag-lead-running-diff.sql) | `LAG` / `LEAD` running differences |
| [`04-rank-vs-dense-rank.sql`](scripts/04-rank-vs-dense-rank.sql) | `ROW_NUMBER` vs `RANK` vs `DENSE_RANK` tie behaviour |
| [`05-covering-index.sql`](scripts/05-covering-index.sql) | Covering index eliminating a Key Lookup |
| [`06-execution-plan-reading.sql`](scripts/06-execution-plan-reading.sql) | Execution plan field guide (Scan/Seek/Lookup/Join, estimated vs actual rows) |
| [`07-query-hints-nolock-forceseek.sql`](scripts/07-query-hints-nolock-forceseek.sql) | `NOLOCK` and `FORCESEEK` hints and their trade-offs |
| [`08-filtered-index.sql`](scripts/08-filtered-index.sql) | Filtered index for a narrow query pattern |

> **Note:** this lab was completed as a theory-first exercise — the scripts are heavily annotated with the mechanics and trade-offs of each feature (as SQL comments) rather than being executed against a live SQL Server instance in this session. Run them against SQL Server 2019+ (LocalDB, Docker `mcr.microsoft.com/mssql/server`, or Azure SQL) with "Include Actual Execution Plan" (Ctrl+M in SSMS/Azure Data Studio) to see the plans described in the comments first-hand.

## Implementation Walkthrough

1. **Schema & seed (`00-schema-and-seed.sql`)** — a small e-commerce domain (`Customers` → `Orders` → `OrderItems`) seeded via the `ROW_NUMBER() OVER (...) FROM sys.all_objects CROSS JOIN sys.all_objects` trick (set-based row generation, no cursor/loop) to reach ~5,000 customers / ~200,000 orders / ~500,000 order items. Row counts were chosen deliberately large enough that the optimizer's cost-based choices (Scan vs Seek, Key Lookup elimination, filtered-index selectivity) are realistic rather than trivially always-a-scan on a tiny table. `UPDATE STATISTICS ... WITH FULLSCAN` is run at the end so later scripts' plans reflect real cardinalities.
2. **CTE vs subquery (`01`)** — same "customers with ≥3 orders" query written both ways to show a CTE is inlined by the optimizer just like a derived table (identical plan for a single-reference CTE); the win is readability, not speed. Recursive CTEs are called out as the one case where a CTE has no subquery equivalent at all.
3. **Pagination (`02`)** — `OFFSET/FETCH` and `ROW_NUMBER()` produce equivalent plans and share the same deep-page cost problem (O(offset), not O(page size)); `ROW_NUMBER()` earns its place when the row number itself is needed or when paginating per-group via `PARTITION BY`. Keyset (seek) pagination is documented as the real fix for deep pages.
4. **LAG/LEAD (`03`)** — per-customer running difference in order value (`PARTITION BY CustomerId ORDER BY OrderDate`), plus `DATEDIFF` between consecutive orders via `LEAD`. Notes that window functions can't be filtered directly in `WHERE` — must wrap in a CTE (ties back to task 1).
5. **RANK vs DENSE_RANK (`04`)** — customers ranked by total spend; a follow-up query isolates rows where `RANK()` and `DENSE_RANK()` diverge, since the seed data's spend formula guarantees ties. Includes a practical rule of thumb for choosing `ROW_NUMBER` (dedup/pagination) vs `RANK` (leaderboard-style gaps) vs `DENSE_RANK` (compact tiers).
6. **Covering index (`05`)** — baseline `IX_Orders_CustomerId` forces a Key Lookup for `Status`/`OrderDate`/`TotalAmount`; adding `IX_Orders_CustomerId_Status_Covering ON (CustomerId, Status) INCLUDE (OrderDate, TotalAmount)` removes it. Documents key-column ordering (equality predicates first) vs `INCLUDE` (SELECT-only columns) and the write-cost trade-off of adding indexes.
7. **Execution plan reading (`06`)** — three queries (forced Scan, forced Seek, Seek+Key Lookup) with `SET STATISTICS IO/TIME ON`, followed by a field guide covering every core operator (Scan, Seek, Key/RID Lookup, Nested Loops/Hash Match/Merge Join, Sort) and how to interpret estimated-vs-actual row divergence.
8. **Query hints (`07`)** — `NOLOCK` (dirty reads / skipped or duplicate rows risk vs. `READ_COMMITTED_SNAPSHOT` as the safer modern alternative) and `FORCESEEK` (bypasses a possibly-wrong cardinality estimate, but is a permanent override that can go stale as data grows). Framed as diagnostic escape hatches, not defaults.
9. **Filtered index (`08`)** — `IX_Orders_Pending_OrderDate ON (OrderDate) INCLUDE (CustomerId, TotalAmount) WHERE Status = 'Pending'` for an "operations dashboard" query that only ever touches the ~5% of rows that are Pending. Covers the exact-predicate-match requirement for the optimizer to use it, and the filtered-unique-index pattern for nullable-column uniqueness as a related real-world use case.

## Common Pitfalls & Troubleshooting

- **CTE performance is not automatic** — a CTE referenced more than once in the outer query can be recomputed each time (it's not cached/materialized by default). Check the execution plan for repeated scans of the same source; use a temp table or table variable if the intermediate result must be computed once and reused.
- **Unstable pagination ordering** — `ORDER BY OrderDate DESC` alone has ties (same millisecond); paginate on a column combination that's a total order (`ORDER BY OrderDate DESC, OrderId DESC`) or rows can repeat or vanish across pages.
- **Window functions can't be filtered in `WHERE`** — `LAG`/`LEAD`/`RANK`/`DENSE_RANK`/`ROW_NUMBER` are evaluated in the same logical phase as `SELECT`, after `WHERE`/`GROUP BY`. Filtering on their result requires wrapping the query in a CTE/derived table.
- **A covering index only covers the query it was designed for** — adding columns to `INCLUDE` helps one query shape; it doesn't help queries with different filter/sort columns, and it adds write overhead on every `INSERT`/`UPDATE`/`DELETE` to that table — don't add one without checking the read pattern is actually frequent (`sys.dm_db_index_usage_stats` in a real environment).
- **Estimated vs actual row count divergence is the #1 plan smell** — driven by stale statistics, parameter sniffing, or predicates the optimizer can't estimate well (e.g. a scalar function wrapping a column). Fix the root cause (`UPDATE STATISTICS`, `OPTION (RECOMPILE)`/`OPTIMIZE FOR UNKNOWN`) rather than reaching for a hint first.
- **`NOLOCK` risk is broader than "dirty reads"** — it can also skip or duplicate rows during concurrent page splits/row moves. Never use it for financial totals or anything feeding a reconciliation/audit process; prefer enabling `READ_COMMITTED_SNAPSHOT` at the database level for non-blocking reads without those correctness risks.
- **`FORCESEEK` (and query hints generally) are diagnostic tools, not permanent fixes** — a forced Seek that's correct today can become the wrong plan later as table size/distribution changes, and the query silently never benefits from future optimizer improvements. Use a hint to confirm a hypothesis, then fix the underlying cause (stats, missing index, parameter sniffing) and remove the hint if possible; document why it's there if it must stay.
- **Filtered indexes require an exact predicate match** — a filtered index `WHERE Status = 'Pending'` is only usable by queries whose `WHERE` clause is provably a subset of that filter (e.g. `Status = 'Pending'`, not `Status IN ('Pending', 'Shipped')`). Also sensitive to non-default `SET` options (`ANSI_NULLS`/`QUOTED_IDENTIFIER`) from legacy clients silently disabling its use.
