/* ============================================================================
   03 - LAG / LEAD: running differences between rows
   ============================================================================
   Topic: for each customer, compute how their order value changed compared
   to their PREVIOUS order (LAG) and their NEXT order (LEAD), ordered by date.
   Requires: 00-schema-and-seed.sql already run.
   ========================================================================= */

USE AdvancedSqlLab;
GO

SELECT
    o.CustomerId,
    o.OrderId,
    o.OrderDate,
    o.TotalAmount,

    -- LAG(expr, offset, default) looks BACKWARD `offset` rows within the
    -- window (default offset = 1 = "previous row"). `default` is what to
    -- return when there is no such row (e.g. the customer's first order).
    LAG(o.TotalAmount, 1, NULL) OVER (
        PARTITION BY o.CustomerId
        ORDER BY o.OrderDate
    ) AS PreviousOrderAmount,

    -- The actual "running difference": current minus previous. NULL for a
    -- customer's very first order, since there's nothing to diff against.
    o.TotalAmount - LAG(o.TotalAmount, 1, NULL) OVER (
        PARTITION BY o.CustomerId
        ORDER BY o.OrderDate
    ) AS ChangeFromPreviousOrder,

    -- LEAD(expr, offset, default) is the mirror image: looks FORWARD.
    -- Useful for "how much will they spend next time" style backfill
    -- analysis, or for computing the gap in days until the NEXT order.
    LEAD(o.OrderDate, 1, NULL) OVER (
        PARTITION BY o.CustomerId
        ORDER BY o.OrderDate
    ) AS NextOrderDate,

    DATEDIFF(
        DAY,
        o.OrderDate,
        LEAD(o.OrderDate, 1, NULL) OVER (PARTITION BY o.CustomerId ORDER BY o.OrderDate)
    ) AS DaysUntilNextOrder

FROM dbo.Orders o
WHERE o.Status <> 'Cancelled'
ORDER BY o.CustomerId, o.OrderDate;
GO

/* ----------------------------------------------------------------------
   HOW IT WORKS / WHY IT MATTERS
   ----------------------------------------------------------------------
   1. LAG/LEAD are "offset" window functions - they don't aggregate rows
      down to one value per group (like SUM/AVG would), they annotate EACH
      row with a value pulled from a sibling row inside the same PARTITION,
      as defined by ORDER BY. The result set keeps one row per input row,
      just with extra computed columns - this is the key difference from
      GROUP BY, which collapses rows.

   2. PARTITION BY CustomerId resets the "previous row" pointer at each
      customer boundary. Without PARTITION BY, LAG would look at the
      previous row in the ENTIRE result set (i.e. the previous customer's
      last order) rather than this customer's previous order - a very
      common bug when people forget PARTITION BY on multi-entity data.

   3. ORDER BY inside OVER(...) defines what "previous" and "next" mean.
      It does NOT have to match the outer query's ORDER BY (though it does
      here) - the window ORDER BY only controls the window function's
      frame, the outer ORDER BY controls final result display order.

   4. Before window functions existed (pre-SQL Server 2012), the same
      "compare to previous row" logic required a self-JOIN on a computed
      row number, e.g.:
          SELECT curr.*, prev.TotalAmount
          FROM Numbered curr
          LEFT JOIN Numbered prev
            ON prev.CustomerId = curr.CustomerId
           AND prev.rn = curr.rn - 1
      That's an O(n) self-join the optimizer has to reason about, versus
      LAG/LEAD which are computed in a single pass over data already sorted
      by the partition/order clause (SQL Server materializes one sort per
      distinct OVER() clause, then streams through it).

   5. Performance note: every DISTINCT OVER(...) specification in a query
      can trigger its own sort operation in the plan. Notice above that
      PreviousOrderAmount and ChangeFromPreviousOrder both use the exact
      same OVER(PARTITION BY o.CustomerId ORDER BY o.OrderDate) - SQL
      Server's optimizer recognizes identical window specs and reuses a
      single sort/segment operation for all of them, rather than sorting
      twice. But a DIFFERENT OVER() clause (like NextOrderDate flipping
      the frame direction, even though the PARTITION/ORDER here happens to
      be identical too) - if you had one window ordered ASC and another
      DESC, that WOULD force a second sort. Check the execution plan for
      the number of Sort operators if you have many different window
      specs in one query.

   6. Pitfall: LAG/LEAD cannot be used directly inside a WHERE clause
      (e.g. "WHERE LAG(TotalAmount) OVER (...) > 100" is not legal SQL)
      because window functions are logically evaluated AFTER WHERE/GROUP BY,
      in the same phase as SELECT. To filter on a window function's result,
      wrap the query in a CTE or derived table and filter in the outer
      query - this is a natural place to combine topics 01 and 03.
   ========================================================================= */
