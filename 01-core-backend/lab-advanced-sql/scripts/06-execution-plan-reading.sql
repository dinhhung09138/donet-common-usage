/* ============================================================================
   06 - Reading a SQL Server Execution Plan
   ============================================================================
   Topic: annotated queries plus a guide (in comments) on how to read Scans,
   Seeks, Lookups, and estimated vs. actual row counts in a plan.
   Requires: 00-schema-and-seed.sql already run.

   In SSMS / Azure Data Studio: enable "Include Actual Execution Plan"
   (Ctrl+M) before running these, so the plan shows ACTUAL row counts
   alongside the optimizer's ESTIMATED ones - the comparison between the
   two is the single most useful diagnostic signal a plan gives you.
   ========================================================================= */

USE AdvancedSqlLab;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- ----------------------------------------------------------------------
-- QUERY 1: forces a SCAN (no usable index for this predicate)
-- ----------------------------------------------------------------------
-- ProductName has no index, so the engine must read every row of
-- OrderItems to find matches - a Clustered Index Scan (or Table Scan on a
-- heap). Look for the "Clustered Index Scan" operator; hover it in the
-- graphical plan (or check the XML) for "Estimated Number of Rows" vs.
-- "Actual Number of Rows" - on a freshly-stats-updated table like this
-- one they should be close; a large gap in a real system usually means
-- stale statistics.
SELECT OrderItemId, OrderId, ProductName, Quantity
FROM dbo.OrderItems
WHERE ProductName = N'Product 137';
GO

-- ----------------------------------------------------------------------
-- QUERY 2: forces a SEEK (an index exists and the predicate is sargable)
-- ----------------------------------------------------------------------
-- IX_Orders_CustomerId supports an equality seek directly on CustomerId.
-- Look for "Index Seek" instead of "Index Scan" - a Seek navigates the
-- B-tree directly to matching rows (cost roughly O(log n) + matches)
-- instead of reading every row (O(n)).
SELECT OrderId, OrderDate, TotalAmount
FROM dbo.Orders
WHERE CustomerId = 42;
GO

-- ----------------------------------------------------------------------
-- QUERY 3: SEEK + Key Lookup (the "before" state from script 05)
-- ----------------------------------------------------------------------
SELECT OrderId, OrderDate, TotalAmount
FROM dbo.Orders
WHERE CustomerId = 42
  AND Status = 'Delivered';
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* ----------------------------------------------------------------------
   READING THE PLAN: a field guide
   ----------------------------------------------------------------------

   OPERATORS - what they mean and their rough cost:

   - Clustered Index Scan / Table Scan
       Reads every row of the table (or every row of the clustered
       index). Cost scales with table size, NOT with how many rows
       actually match the predicate. Not inherently "bad" - if a query
       needs most of a small table, a Scan can beat a Seek, since a Seek
       has per-row navigation overhead a Scan avoids. Becomes a problem
       when the table is large and the query only wants a small subset -
       the classic sign that a supporting index is missing.

   - Index Seek
       Navigates the B-tree directly to the range of matching rows using
       the index key. Cost is roughly proportional to (tree depth + rows
       returned), largely independent of total table size. This is the
       operator you generally WANT for selective point/range queries.

   - Key Lookup (Clustered) / RID Lookup (heap)
       "I found the row I want in a non-covering index, but I need
       columns that aren't in that index, so go fetch them from the base
       table." Executed once PER MATCHING ROW via a Nested Loops join -
       cheap for a handful of rows, expensive when thousands of rows all
       need a lookup (that's exactly what script 05's covering index
       eliminates).

   - Nested Loops / Hash Match / Merge Join
       The three JOIN strategies. Nested Loops: for each row on one side,
       probe the other side (good when one side is small / well-indexed).
       Hash Match: build an in-memory hash table from one side, probe with
       the other (good for large, unsorted, unindexed sets - but memory-
       hungry, can spill to tempdb). Merge Join: both inputs already
       sorted on the join key, walk them in lockstep (good when both
       sides are pre-sorted, e.g. two clustered index scans on join
       columns). The optimizer picks based on estimated row counts, so a
       bad estimate can pick a poor JOIN strategy even when the "right"
       one is possible.

   - Sort
       Explicit sort operator, needed for ORDER BY without a supporting
       index, or before Merge Join/certain aggregates. Sorts are memory-
       intensive and can spill to tempdb (visible as a warning icon on
       the operator) if the optimizer under-estimated row count and
       under-allocated memory.

   READING COST: each operator shows a "Cost: X%" (relative to the total
   batch cost, always adds to ~100% within one query). This is an
   ESTIMATE based on the optimizer's internal cost model (CPU + I/O
   heuristics), not a measured wall-clock time - useful for spotting
   which operator dominates, not for absolute timing (use STATISTICS TIME
   or an extended events trace for real timing).

   ESTIMATED VS ACTUAL ROWS - the most important number to check:
   Every operator in an ACTUAL plan (Ctrl+M) shows both. The optimizer
   picks its entire strategy (Seek vs Scan, join type, memory grant)
   based on the ESTIMATED count, derived from statistics histograms. If
   Estimated and Actual diverge wildly (a common rule of thumb: >10x off,
   though the right threshold depends on absolute row counts) the
   optimizer likely picked a suboptimal plan built on wrong assumptions.
   Common causes: stale statistics (fix: UPDATE STATISTICS or rebuild
   index), a parameter-sniffed plan cached for an unusually
   small/large parameter value, or a predicate the optimizer can't
   estimate well (e.g. a scalar function wrapped around a column, a
   complex multi-column correlation the histogram doesn't capture).

   SET STATISTICS IO ON output - read this alongside the plan:
     Table 'Orders'. Scan count 1, logical reads 4, ...
   "Logical reads" = pages read from the buffer pool (memory) for this
   table. Compare this number between two versions of a query (e.g.
   script 05's before/after) as a stable, cache-independent measure of
   I/O cost - more reliable for comparison than wall-clock duration,
   which fluctuates with what's already cached, other load, etc.
   ========================================================================= */
