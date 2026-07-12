/* ============================================================================
   07 - Query Hints: NOLOCK and FORCESEEK
   ============================================================================
   Topic: apply two commonly-misused query hints and document their
   trade-offs in detail. Both hints override the optimizer's default
   behavior and both carry real risk - this script leans heavily on the
   "when NOT to use this" side.
   Requires: 00-schema-and-seed.sql already run.
   ========================================================================= */

USE AdvancedSqlLab;
GO

-- ----------------------------------------------------------------------
-- HINT 1: NOLOCK (equivalent to READUNCOMMITTED isolation, per-table)
-- ----------------------------------------------------------------------
-- Normally, under the default READ COMMITTED isolation level, a reading
-- query takes shared locks (or, with READ_COMMITTED_SNAPSHOT enabled,
-- reads a committed-as-of-statement-start row version) so it never sees a
-- half-written row from a concurrent transaction. NOLOCK tells the engine
-- to skip that protection entirely for this table reference.
SELECT o.OrderId, o.CustomerId, o.Status, o.TotalAmount
FROM dbo.Orders AS o WITH (NOLOCK)
WHERE o.CustomerId = 42;
GO

/* ----------------------------------------------------------------------
   NOLOCK trade-off:

   WHAT YOU GAIN: the read takes no shared locks, so it cannot be blocked
   by (and does not block) concurrent writers on the same rows/pages. On a
   busy OLTP table with heavy write contention, this can visibly reduce
   blocking chains for reporting-style queries.

   WHAT YOU RISK - "dirty reads" is the least of it:
     - Dirty reads: you can read a row a concurrent transaction has
       modified but NOT YET COMMITTED - if that transaction later rolls
       back, you've returned data that never officially existed.
     - Skipped rows: if a page split or row-move happens concurrently
       (e.g. an UPDATE that grows a variable-length column, or a page
       split during concurrent INSERTs), NOLOCK can miss rows that
       physically moved to a different page during your scan - it does
       not guarantee you see the whole table even as-of a point in time.
     - DUPLICATE rows: for the same reason (a row can appear to be
       scanned twice if it moved to a page your scan hasn't reached yet).
     - Torn/corrupted-looking reads: in rare cases you can read a row
       mid-update where some columns reflect the new value and others the
       old, if you read while a multi-column UPDATE is only partially
       applied at the storage-page level.

   WHEN IT'S DEFENSIBLE: approximate reporting/dashboards where
   "occasionally off by a row or a few dollars" is acceptable and the
   business has explicitly signed off on that trade-off - NEVER for
   financial totals, inventory counts feeding a decision, or anything
   downstream of a compliance/audit requirement. In this lab's schema,
   using NOLOCK to read OrderId/CustomerId for a UI list is a reasonable
   example; using NOLOCK to compute "TotalAmount SUM to reconcile against
   payments" would not be.

   MODERN ALTERNATIVE: READ_COMMITTED_SNAPSHOT (RCSI) or SNAPSHOT
   isolation give you non-blocking reads WITHOUT the dirty-read/skipped-
   row risk, by reading a consistent row-versioned snapshot instead of
   skipping locks altogether. If a database allows enabling
   READ_COMMITTED_SNAPSHOT ON, that is almost always the better fix for
   "reads are getting blocked by writers" than sprinkling NOLOCK hints
   through the codebase - it's a database-level setting instead of a
   query-by-query judgment call, and it doesn't have NOLOCK's correctness
   risks (it costs tempdb space for row versions instead).
   ---------------------------------------------------------------------- */


-- ----------------------------------------------------------------------
-- HINT 2: FORCESEEK
-- ----------------------------------------------------------------------
-- Forces the optimizer to use an Index Seek against the specified index
-- (or any index, if unspecified) rather than whatever access method it
-- would otherwise choose (typically a Scan).
SELECT o.OrderId, o.OrderDate, o.TotalAmount
FROM dbo.Orders AS o WITH (FORCESEEK)
WHERE o.CustomerId = 42
  AND o.OrderDate > DATEADD(MONTH, -1, SYSDATETIME());
GO

-- You can also target a specific index and even specific key columns to
-- seek on, for full control:
SELECT o.OrderId, o.OrderDate, o.TotalAmount
FROM dbo.Orders AS o WITH (FORCESEEK (IX_Orders_CustomerId (CustomerId)))
WHERE o.CustomerId = 42
  AND o.OrderDate > DATEADD(MONTH, -1, SYSDATETIME());
GO

/* ----------------------------------------------------------------------
   FORCESEEK trade-off:

   WHY IT EXISTS: the optimizer sometimes chooses a Scan over a Seek when
   its cardinality ESTIMATE (see script 06) is wrong - e.g. it thinks a
   predicate will match 40% of the table (favoring a Scan) when in
   production, with real data, it actually matches 0.1% (where a Seek
   would be far cheaper). This commonly happens with:
     - Stale statistics that don't reflect current data distribution.
     - Parameter sniffing: a stored procedure's plan gets cached based on
       the FIRST parameter value it was called with, and that plan (Scan
       or Seek) may be wrong for later, differently-shaped parameter
       values.
     - Correlated predicates the single-column statistics histograms
       can't capture (e.g. CustomerId and Status are correlated in ways
       the optimizer assumes independence about).

   WHAT YOU RISK: FORCESEEK is a blunt instrument - you are telling the
   engine "I know better than your cost-based estimate," permanently,
   for every future execution of this query, regardless of how the data
   distribution changes over time. If the table's data shape changes
   later (e.g. this customer now has 100,000 orders instead of 40), the
   forced Seek could become the WORSE choice and you won't get the
   Scan-based plan the optimizer would otherwise have picked - the hint
   doesn't know that, it just always forces a Seek. Hints also make plans
   more fragile across SQL Server version upgrades, since you're opting
   out of future optimizer improvements for this query.

   WHEN IT'S DEFENSIBLE: as a targeted, TEMPORARY diagnostic tool to
   confirm "yes, a Seek really would be faster here" while you fix the
   ROOT CAUSE (update stats, add a missing index, fix parameter sniffing
   with OPTION (RECOMPILE) or OPTIMIZE FOR hints, or add
   OPTION (OPTIMIZE FOR UNKNOWN) for parameter-sniffing cases). Shipping
   FORCESEEK as a permanent fix instead of addressing why the optimizer
   chose wrong is treating a symptom, not the disease - document WHY the
   hint is there (as this comment does) so a future engineer doesn't
   remove it blindly, and revisit it periodically as data grows.

   GENERAL RULE FOR BOTH HINTS: query hints are an escape hatch for when
   you have DIAGNOSED, specific evidence the optimizer is wrong (bad
   estimate, contention, stale stats) - not a default tool reached for
   preemptively "to be safe" or "for performance." Every hint is a
   promise to future maintainers that you understood the trade-off; an
   undocumented hint is a maintenance trap.
   ========================================================================= */
