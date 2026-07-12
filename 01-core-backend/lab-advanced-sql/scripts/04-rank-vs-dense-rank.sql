/* ============================================================================
   04 - RANK vs DENSE_RANK: gap behavior with tied values
   ============================================================================
   Topic: rank customers by total spend, and show how RANK() and
   DENSE_RANK() handle ties differently. ROW_NUMBER() is included too, as a
   3rd point of comparison, since all three are commonly confused.
   Requires: 00-schema-and-seed.sql already run.
   ========================================================================= */

USE AdvancedSqlLab;
GO

WITH CustomerSpend AS
(
    SELECT
        o.CustomerId,
        SUM(o.TotalAmount) AS TotalSpend
    FROM dbo.Orders o
    WHERE o.Status <> 'Cancelled'
    GROUP BY o.CustomerId
)
SELECT
    cs.CustomerId,
    cs.TotalSpend,

    -- ROW_NUMBER: always unique, 1,2,3,4,5... even for tied TotalSpend
    -- values, the tie is broken arbitrarily (or by a secondary ORDER BY
    -- you add). No gaps, no repeats - purely positional.
    ROW_NUMBER() OVER (ORDER BY cs.TotalSpend DESC) AS RowNum,

    -- RANK: ties share the SAME rank, and the NEXT rank after a tie SKIPS
    -- ahead by the number of tied rows. E.g. two customers tied for rank 2
    -- means the next customer is rank 4, not 3 - "2, 2, 4, 5..."
    RANK() OVER (ORDER BY cs.TotalSpend DESC) AS Rnk,

    -- DENSE_RANK: ties also share the same rank, but the NEXT rank is
    -- always current + 1, no gap - "2, 2, 3, 4..."
    DENSE_RANK() OVER (ORDER BY cs.TotalSpend DESC) AS DenseRnk

FROM CustomerSpend cs
ORDER BY cs.TotalSpend DESC;
GO

-- A compact way to SEE the divergence directly: find the exact spot where
-- RANK and DENSE_RANK disagree because of a tie.
WITH CustomerSpend AS
(
    SELECT o.CustomerId, SUM(o.TotalAmount) AS TotalSpend
    FROM dbo.Orders o
    WHERE o.Status <> 'Cancelled'
    GROUP BY o.CustomerId
),
Ranked AS
(
    SELECT
        cs.*,
        RANK()       OVER (ORDER BY cs.TotalSpend DESC) AS Rnk,
        DENSE_RANK() OVER (ORDER BY cs.TotalSpend DESC) AS DenseRnk
    FROM CustomerSpend cs
)
SELECT *
FROM Ranked
WHERE Rnk <> DenseRnk
ORDER BY Rnk;
GO

/* ----------------------------------------------------------------------
   HOW IT WORKS / WHY IT MATTERS
   ----------------------------------------------------------------------
   1. All three (ROW_NUMBER, RANK, DENSE_RANK) are ranking window
      functions: they require an OVER (ORDER BY ...) clause (PARTITION BY
      is optional, same as any window function) and assign an integer to
      each row based on its position in that order.

   2. The difference is entirely about how ties (equal ORDER BY values)
      are handled:
        - ROW_NUMBER: ignores ties completely, always 1..N with no repeats.
        - RANK: ties get the same number; the count of tied rows is
          "spent" as a gap before the next distinct value (SQL-standard
          "Olympic ranking" - like two silver medalists means no bronze,
          next place is 4th).
        - DENSE_RANK: ties get the same number; NO gap afterward - useful
          when you want to say "there are N distinct spend tiers" rather
          than "this row is in absolute position N".

   3. Practical selection rule:
        - Use ROW_NUMBER for pagination / "give me exactly one row per
          group" deduplication (e.g. "keep only the latest order per
          customer": ROW_NUMBER() OVER (PARTITION BY CustomerId ORDER BY
          OrderDate DESC) = 1).
        - Use RANK for leaderboards / competition-style ranking where
          skipped positions are the expected, correct semantic (e.g.
          "top 10 customers by spend" where a 3-way tie for #1 should
          mean there IS no #2 or #3).
        - Use DENSE_RANK when you want compact tier numbers, e.g. bucketing
          customers into spend tiers or numbering distinct price points
          without gaps.

   4. Since the demo data's TotalAmount is derived from `(n % 490) + 10`
      (see seed script), many customers will have IDENTICAL TotalSpend
      sums purely by construction - this is intentional so the RANK vs
      DENSE_RANK gap is guaranteed to be visible rather than a rare edge
      case you might not otherwise trigger on random real-world data.

   5. Pitfall: none of these three functions can be used in WHERE (same
      restriction as LAG/LEAD in script 03) since ranking is computed at
      the same logical phase as SELECT, after WHERE/GROUP BY. To filter
      "top 10 ranked customers", wrap in a CTE/derived table:
          WITH Ranked AS (SELECT ..., RANK() OVER (...) AS Rnk FROM ...)
          SELECT * FROM Ranked WHERE Rnk <= 10;
      TOP (10) WITH TIES achieves something similar directly for RANK-like
      semantics without an explicit ranking column, but only for the
      single outermost ORDER BY - it doesn't expose the rank value itself.
   ========================================================================= */
