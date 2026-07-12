/* ============================================================================
   05 - Covering Index: eliminating a Key Lookup
   ============================================================================
   Topic: create a covering index and verify (via the execution plan) that it
   removes a Key Lookup operator that a non-covering index would need.
   Requires: 00-schema-and-seed.sql already run.
   ========================================================================= */

USE AdvancedSqlLab;
GO

-- Target query: "list OrderId, OrderDate and TotalAmount for a customer's
-- Delivered orders". This is a realistic "order history screen" query.
DECLARE @CustomerId INT = 42;

SELECT o.OrderId, o.OrderDate, o.TotalAmount
FROM dbo.Orders o
WHERE o.CustomerId = @CustomerId
  AND o.Status = 'Delivered';
GO

/* ----------------------------------------------------------------------
   BEFORE: baseline index situation (from 00-schema-and-seed.sql)
   ----------------------------------------------------------------------
   IX_Orders_CustomerId ON dbo.Orders(CustomerId)

   This index is a B-tree keyed on CustomerId. Each leaf-level entry
   contains the CustomerId value plus a pointer back to the corresponding
   row in the CLUSTERED index (the table's PRIMARY KEY, OrderId here) -
   this pointer-back step is called a Key Lookup (called "RID Lookup" if
   the table were a heap with no clustered index).

   For the query above, SQL Server can:
     1. SEEK into IX_Orders_CustomerId to find rows where CustomerId = 42
        (fast - it's an equality match on the index key).
     2. But CustomerId alone doesn't tell it Status, OrderDate, or
        TotalAmount - those columns aren't IN this index. So for EVERY
        matching row, it must do a Key Lookup back into the clustered
        index to fetch Status (to apply the second WHERE filter) and the
        SELECT columns.

   With SET STATISTICS IO ON before running the query, you'd see TWO scan
   counts in the output: one against Orders via the index seek, and a
   second (logical reads) driven by the Key Lookup - and in the graphical
   plan, an explicit "Key Lookup (Clustered)" operator connected to the
   Index Seek by a Nested Loops join, usually drawn as a THICK arrow
   (proportionally sized to row count) - that arrow width is the visual
   giveaway of a lookup-per-row cost.
   ---------------------------------------------------------------------- */

-- ----------------------------------------------------------------------
-- AFTER: covering index using INCLUDE
-- ----------------------------------------------------------------------
-- INCLUDE adds columns to the leaf level of the index WITHOUT making them
-- part of the index KEY (so they don't affect sort order or seek
-- predicates, but they ARE available to satisfy the query without going
-- back to the clustered index).
CREATE INDEX IX_Orders_CustomerId_Status_Covering
    ON dbo.Orders (CustomerId, Status)      -- key columns: used for seek + filter
    INCLUDE (OrderDate, TotalAmount);       -- included columns: used for SELECT only

-- Re-run the same query - the plan should now show a single Index Seek
-- with NO Key Lookup, because every column the query needs (CustomerId,
-- Status, OrderDate, TotalAmount) exists at the leaf level of this index.
DECLARE @CustomerId INT = 42;

SELECT o.OrderId, o.OrderDate, o.TotalAmount
FROM dbo.Orders o
WHERE o.CustomerId = @CustomerId
  AND o.Status = 'Delivered';
GO

/* ----------------------------------------------------------------------
   HOW IT WORKS / WHY IT MATTERS
   ----------------------------------------------------------------------
   1. "Covering index" = an index that contains EVERY column the query
      references (in the SELECT list, WHERE, JOIN, ORDER BY, GROUP BY) so
      the engine never needs to visit the base table/clustered index at
      all. It's called "covering" because it fully covers the query's
      column needs.

   2. Key column order matters: CustomerId first, then Status - because
      the query filters CustomerId with equality AND Status with equality,
      putting the more selective/leading predicate first (CustomerId, since
      there are ~5,000 distinct customers vs. only 4 distinct Status
      values) lets the seek narrow down fast, then Status further narrows
      within that customer's rows without an extra lookup. If the query
      instead did a RANGE filter on one column (e.g. OrderDate BETWEEN...)
      the range column should generally go LAST in the key, since a B-tree
      can only seek efficiently on a "sargable" prefix followed by at
      most one range predicate.

   3. INCLUDE vs. putting everything in the key: columns only used in
      SELECT (not filtered/joined/sorted on) belong in INCLUDE, not the
      key. Key columns increase the size of every level of the B-tree
      (impacting seek depth and non-leaf page count); included columns
      only bloat the LEAF level, which is cheaper and doesn't affect the
      tree's seek performance.

   4. Cost trade-off - covering indexes aren't free: every additional
      index adds storage AND slows down INSERT/UPDATE/DELETE, since the
      engine must maintain the index on every write. For a table with
      heavy write traffic (Orders here, in production, is probably
      write-heavy), a wide covering index designed for one read pattern
      can measurably hurt insert throughput - the tradeoff is only worth
      it when the read query it serves is frequent/critical enough (e.g.
      an order-history screen hit on every page load) to outweigh the
      write cost. Always check sys.dm_db_index_usage_stats in a real
      environment before adding one, to confirm the read pattern is
      actually common.

   5. Verifying the fix: the correct way to "verify it eliminated a Key
      Lookup" is to capture the actual execution plan (Ctrl+M in SSMS /
      "Include Actual Execution Plan") for both the BEFORE and AFTER
      query, and confirm the Key Lookup operator is present in one and
      absent in the other - plus compare SET STATISTICS IO output: the
      "logical reads" count on Orders should drop noticeably once the
      Key Lookup is gone, since each lookup previously cost roughly one
      extra logical read per matching row (worse for OLTP-style point
      queries where the lookup count scales with row count returned).
   ========================================================================= */
