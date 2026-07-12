/* ============================================================================
   01 - CTE vs Nested Subquery
   ============================================================================
   Topic: rewrite a nested subquery as a CTE for readability AND performance.
   Requires: 00-schema-and-seed.sql already run.

   Goal query: "for each customer, show their total spend and their most
   recent order date, but only for customers who have placed at least 3
   orders."
   ========================================================================= */

USE AdvancedSqlLab;
GO

-- ----------------------------------------------------------------------
-- BEFORE: nested subquery
-- ----------------------------------------------------------------------
-- Every level of nesting here is a derived table that SQL Server must
-- materialize (conceptually) or inline before it can execute the outer
-- query. As nesting grows, this becomes hard to read top-down - you have
-- to parse from the innermost parentheses outward to understand intent.
SELECT
    c.CustomerId,
    c.Name,
    sub.TotalSpend,
    sub.LastOrderDate
FROM dbo.Customers c
INNER JOIN
(
    SELECT
        o.CustomerId,
        SUM(o.TotalAmount) AS TotalSpend,
        MAX(o.OrderDate)   AS LastOrderDate,
        COUNT(*)           AS OrderCount
    FROM dbo.Orders o
    WHERE o.Status <> 'Cancelled'
    GROUP BY o.CustomerId
) AS sub ON sub.CustomerId = c.CustomerId
WHERE sub.OrderCount >= 3
ORDER BY sub.TotalSpend DESC;
GO

-- ----------------------------------------------------------------------
-- AFTER: CTE (Common Table Expression)
-- ----------------------------------------------------------------------
-- Same logic, but named and declared before the query that uses it. A CTE
-- is NOT a temp table - it is not materialized to disk or memory by default;
-- it's closer to a named, scoped view that only exists for the statement
-- that follows it. The optimizer is free to inline it into the final plan
-- exactly like the subquery version above.
WITH CustomerOrderSummary AS
(
    SELECT
        o.CustomerId,
        SUM(o.TotalAmount) AS TotalSpend,
        MAX(o.OrderDate)   AS LastOrderDate,
        COUNT(*)           AS OrderCount
    FROM dbo.Orders o
    WHERE o.Status <> 'Cancelled'
    GROUP BY o.CustomerId
)
SELECT
    c.CustomerId,
    c.Name,
    cos.TotalSpend,
    cos.LastOrderDate
FROM dbo.Customers c
INNER JOIN CustomerOrderSummary cos ON cos.CustomerId = c.CustomerId
WHERE cos.OrderCount >= 3
ORDER BY cos.TotalSpend DESC;
GO

/* ----------------------------------------------------------------------
   HOW IT WORKS / WHY IT MATTERS
   ----------------------------------------------------------------------
   1. Performance: for a SINGLE-reference CTE like this one, the query
      optimizer produces an IDENTICAL execution plan to the subquery
      version. A CTE is syntactic sugar - it gets expanded ("inlined") into
      the query tree at compile time, same as a derived table. Run both
      with SET STATISTICS IO, TIME ON and you'll see matching logical
      reads. So the win here is readability, not raw speed.

   2. Where CTEs DO change performance: recursive CTEs (hierarchies /
      org charts / bill-of-materials) have no nested-subquery equivalent
      at all - that's the one case where a CTE is not just sugar but a
      distinct capability (WITH cte AS (... UNION ALL SELECT ... FROM cte)).

   3. The readability win is real and compounds: with a CTE you read
      top-to-bottom ("first compute this summary, then join it"), matching
      how you'd verbally explain the query. Nested subqueries force you to
      read inside-out. This matters most once you have 2-3 levels of
      nesting or multiple subqueries referencing similar logic.

   4. Multiple CTEs can be chained (WITH A AS (...), B AS (...) SELECT ...
      FROM A JOIN B) which has no clean subquery equivalent without
      duplicating logic or introducing more nesting.

   5. Pitfall: if you reference the SAME CTE more than once in the outer
      query, SQL Server may (depending on the plan) recompute it EACH TIME
      it's referenced - a CTE is not automatically cached/materialized. If
      you need the intermediate result computed once and reused multiple
      times, use a temp table (#temp) or table variable instead, and
      verify with the actual execution plan whether the CTE's underlying
      scan appears once or multiple times.
   ========================================================================= */
