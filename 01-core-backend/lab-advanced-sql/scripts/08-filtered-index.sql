/* ============================================================================
   08 - Filtered Index
   ============================================================================
   Topic: create a filtered index and a query that uses it.
   Requires: 00-schema-and-seed.sql already run.

   Business scenario: an "operations dashboard" repeatedly queries only
   Pending orders (the ones that still need action) - about 5% of all rows
   per the seed script's `n % 20 = 0` distribution. Indexing the WHOLE
   Orders table for a query that only ever touches 5% of it is wasteful.
   ========================================================================= */

USE AdvancedSqlLab;
GO

-- Target query: "show all Pending orders older than 2 days, oldest first"
SELECT OrderId, CustomerId, OrderDate, TotalAmount
FROM dbo.Orders
WHERE Status = 'Pending'
  AND OrderDate < DATEADD(DAY, -2, SYSDATETIME())
ORDER BY OrderDate ASC;
GO

-- ----------------------------------------------------------------------
-- A FILTERED INDEX: a normal B-tree index, but with a WHERE clause that
-- restricts which rows are included at all. The index only has entries
-- for rows matching the filter predicate - here, only Pending orders.
-- ----------------------------------------------------------------------
CREATE INDEX IX_Orders_Pending_OrderDate
    ON dbo.Orders (OrderDate)
    INCLUDE (CustomerId, TotalAmount)
    WHERE Status = 'Pending';
GO

-- Re-run the same query - the plan should show a Seek against
-- IX_Orders_Pending_OrderDate. Because the index's filter predicate
-- (Status = 'Pending') exactly matches the query's Status = 'Pending'
-- predicate, the optimizer can use this index and doesn't need to
-- re-check Status per row - and every column the query needs (OrderId
-- via the clustering key carried at the leaf, CustomerId, TotalAmount)
-- is already covered, so no Key Lookup either.
SELECT OrderId, CustomerId, OrderDate, TotalAmount
FROM dbo.Orders
WHERE Status = 'Pending'
  AND OrderDate < DATEADD(DAY, -2, SYSDATETIME())
ORDER BY OrderDate ASC;
GO

/* ----------------------------------------------------------------------
   HOW IT WORKS / WHY IT MATTERS
   ----------------------------------------------------------------------
   1. A regular (non-filtered) index on (Status, OrderDate) would work
      too, but it would contain an entry for EVERY row in the table -
      Delivered, Shipped, Cancelled, and Pending alike (~200,000 rows in
      this seed) - even though only Pending rows (~10,000, ~5%) are ever
      queried through it. A filtered index only stores entries for the
      ~5% of rows matching `WHERE Status = 'Pending'`, so it is:
        - Smaller on disk (less storage, more of it fits in buffer pool
          memory, so more of it stays cached).
        - Faster to maintain on writes - an INSERT/UPDATE only touches this
          index if the row (before or after the write) matches the filter,
          e.g. inserting a Delivered order doesn't touch this index at all.
        - Cheaper for the optimizer to seek, since the whole index IS the
          relevant subset - no wasted B-tree levels covering rows that
          will never be selected by this query pattern.

   2. Filtered indexes need a SARGABLE, exact-match predicate that the
      QUERY's WHERE clause can be proven to be a SUBSET of, for the
      optimizer to consider using it. `Status = 'Pending'` in the index
      filter and `Status = 'Pending'` in the query match exactly - safe.
      If the query instead said `WHERE Status IN ('Pending', 'Shipped')`,
      the optimizer could NOT use this filtered index alone (it doesn't
      contain Shipped rows) - it would need a different index or a Scan/
      merge with another index. Filtered indexes are narrow-purpose by
      design: one index serves one specific predicate shape well, not a
      family of related queries.

   3. A common real-world use of the SAME technique: a filtered UNIQUE
      index enforcing "at most one row where SomeColumn IS NOT NULL",
      e.g. `CREATE UNIQUE INDEX ... ON Table(Email) WHERE Email IS NOT
      NULL` - lets you have many NULL emails (unconstrained) while still
      guaranteeing uniqueness among the non-NULL ones, which a plain
      UNIQUE constraint can't express (a plain unique index would allow
      only ONE NULL total under SQL Server's default null-handling, or
      would need workarounds otherwise).

   4. Pitfall: statistics on a filtered index are also filtered (scoped
      to the subset), which is normally a benefit (more accurate
      cardinality estimates for that subset) but means the optimizer
      needs the filtered index's OWN statistics to be up to date
      separately from the table's general statistics - `UPDATE STATISTICS
      dbo.Orders` updates all of them, but be aware they're tracked
      per-index-name in DMVs like sys.dm_db_stats_properties when
      diagnosing staleness.

   5. Pitfall: filtered indexes cannot be used by a query running under
      certain non-default SET options (this affects a handful of ANSI
      SET options like ANSI_NULLS/QUOTED_IDENTIFIER - most modern
      clients set these correctly by default, but a legacy ODBC/OLE DB
      client that overrides them can silently cause the optimizer to fall
      back to ignoring the filtered index entirely, with no error, just a
      worse plan).
   ========================================================================= */
