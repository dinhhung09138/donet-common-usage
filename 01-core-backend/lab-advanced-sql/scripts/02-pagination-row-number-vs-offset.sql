/* ============================================================================
   02 - Pagination: ROW_NUMBER() OVER (ORDER BY ...) vs OFFSET/FETCH
   ============================================================================
   Topic: two ways to page through Orders, ordered by OrderDate descending.
   Requires: 00-schema-and-seed.sql already run.
   ========================================================================= */

USE AdvancedSqlLab;
GO

DECLARE @PageNumber INT = 100;   -- page 100 of results
DECLARE @PageSize   INT = 20;

-- ----------------------------------------------------------------------
-- OPTION A: OFFSET / FETCH (SQL Server 2012+, ANSI standard syntax)
-- ----------------------------------------------------------------------
-- Simplest to write. Under the hood SQL Server still has to produce rows
-- in ORDER BY OrderDate DESC order and then walk past (skip) the first
-- @Offset of them before it can start returning results.
SELECT OrderId, CustomerId, OrderDate, TotalAmount
FROM dbo.Orders
ORDER BY OrderDate DESC
OFFSET (@PageNumber - 1) * @PageSize ROWS
FETCH NEXT @PageSize ROWS ONLY;
GO

-- ----------------------------------------------------------------------
-- OPTION B: ROW_NUMBER() OVER (ORDER BY ...) wrapped in an outer filter
-- ----------------------------------------------------------------------
DECLARE @PageNumber INT = 100;
DECLARE @PageSize   INT = 20;

WITH NumberedOrders AS
(
    SELECT
        OrderId, CustomerId, OrderDate, TotalAmount,
        ROW_NUMBER() OVER (ORDER BY OrderDate DESC) AS RowNum
    FROM dbo.Orders
)
SELECT OrderId, CustomerId, OrderDate, TotalAmount
FROM NumberedOrders
WHERE RowNum BETWEEN (@PageNumber - 1) * @PageSize + 1 AND @PageNumber * @PageSize;
GO

/* ----------------------------------------------------------------------
   HOW IT WORKS / WHY IT MATTERS
   ----------------------------------------------------------------------
   1. Functionally these two produce the SAME result set, and on a plain
      single-column ORDER BY like this, SQL Server's optimizer typically
      generates near-identical plans for both - OFFSET/FETCH is itself
      implemented internally using the same "sort + count rows + discard"
      or, when a supporting index exists, a seek that skips directly to
      the Nth row.

   2. Both suffer the SAME fundamental problem on deep pages: without a
      supporting index that matches the ORDER BY, the engine must produce
      ALL rows up to the requested page in sorted order before it can
      discard the ones before the offset. Page 1 (OFFSET 0) is cheap.
      Page 10,000 (OFFSET 200,000) means sorting/walking 200,020 rows to
      return the last 20 - cost grows linearly with page depth. This is
      the classic "OFFSET pagination doesn't scale" problem, and it is
      NOT solved by switching between these two syntaxes.

   3. When ROW_NUMBER() earns its place over OFFSET/FETCH:
      - You need the row number itself in the result (e.g. "#1 - #20"
        displayed to the user) - OFFSET/FETCH doesn't expose it.
      - You need pagination logic COMBINED with PARTITION BY, e.g.
        "top 5 most recent orders PER CUSTOMER" - OFFSET/FETCH has no
        per-group equivalent, but ROW_NUMBER() OVER (PARTITION BY
        CustomerId ORDER BY OrderDate DESC) does this directly.
      - You're on an older SQL Server version (pre-2012) or another
        engine without OFFSET/FETCH support.

   4. The REAL fix for deep pagination is "keyset pagination" (aka seek
      method): instead of "give me rows 200,001-200,020", track the last
      seen OrderDate/OrderId from the previous page and query
      "WHERE OrderDate < @LastSeenOrderDate ORDER BY OrderDate DESC
      OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY" (or plain TOP). With an index
      on OrderDate, this is an index seek directly to the right spot
      regardless of how deep the page is - O(page size), not O(offset).
      Trade-off: you lose the ability to jump to an arbitrary page number
      ("go to page 500") since you only know how to move forward/backward
      from a cursor position - which is why most infinite-scroll / API
      pagination in production systems use keyset, while page-number UIs
      (page 1, 2, 3...) tend to accept the OFFSET cost up to a reasonable
      limit.

   5. Pitfall: ORDER BY must be on a UNIQUE (or unique-enough) key/tuple for
      pagination to be stable across pages. OrderDate alone can have ties
      (two orders in the same millisecond) - if the sort isn't
      deterministic, the same row can appear on two pages or vanish
      between them as data changes. Prefer ORDER BY OrderDate DESC,
      OrderId DESC to guarantee a total order.
   ========================================================================= */
