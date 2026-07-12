/* ============================================================================
   00 - Shared Schema & Seed Data (SQL Server / T-SQL)
   ============================================================================
   Purpose: every other script in this lab (01-08) assumes this schema exists.
   Run this once against a scratch database before running the topic scripts.

   Domain: a small e-commerce store - Customers place Orders, each Order has
   OrderItems (line items). This shape is deliberately reused across every
   topic so JOINs, GROUP BY, and window functions in later scripts all read
   naturally as "per customer" / "per order" analysis.

   Why the row counts matter: index and execution-plan behavior (Scan vs
   Seek, Key Lookup elimination, filtered index selectivity) only shows up
   meaningfully once a table has enough rows that SQL Server's cost-based
   optimizer starts caring about I/O cost. A 20-row demo table will make the
   optimizer choose a Scan for *everything* because a Scan is cheaper than a
   Seek + Lookup below a certain row count - so the seed here targets
   ~5,000 customers / ~200,000 orders / ~500,000 order items.
   ========================================================================= */

IF DB_ID('AdvancedSqlLab') IS NULL
BEGIN
    CREATE DATABASE AdvancedSqlLab;
END
GO

USE AdvancedSqlLab;
GO

DROP TABLE IF EXISTS dbo.OrderItems;
DROP TABLE IF EXISTS dbo.Orders;
DROP TABLE IF EXISTS dbo.Customers;
GO

CREATE TABLE dbo.Customers
(
    CustomerId  INT IDENTITY(1,1) PRIMARY KEY,
    Name        NVARCHAR(100)   NOT NULL,
    Country     NVARCHAR(50)    NOT NULL,
    SignupDate  DATE            NOT NULL
);

CREATE TABLE dbo.Orders
(
    OrderId      INT IDENTITY(1,1) PRIMARY KEY,
    CustomerId   INT             NOT NULL REFERENCES dbo.Customers(CustomerId),
    OrderDate    DATETIME2       NOT NULL,
    Status       VARCHAR(20)     NOT NULL,   -- 'Pending' | 'Shipped' | 'Delivered' | 'Cancelled'
    TotalAmount  DECIMAL(10,2)   NOT NULL
);

CREATE TABLE dbo.OrderItems
(
    OrderItemId  INT IDENTITY(1,1) PRIMARY KEY,
    OrderId      INT             NOT NULL REFERENCES dbo.Orders(OrderId),
    ProductName  NVARCHAR(100)   NOT NULL,
    Quantity     INT             NOT NULL,
    UnitPrice    DECIMAL(10,2)   NOT NULL
);
GO

-- Only Orders.CustomerId has a supporting (non-unique) index by default via
-- the FK - SQL Server does NOT auto-create an index for FKs, so add the
-- baseline ones you'd expect on any real schema. Scripts 05/08 add MORE
-- indexes on top of this baseline to demonstrate specific optimizations -
-- do not add a covering or filtered index here, that would spoil the
-- "before" state those scripts rely on.
CREATE INDEX IX_Orders_CustomerId ON dbo.Orders(CustomerId);
CREATE INDEX IX_OrderItems_OrderId ON dbo.OrderItems(OrderId);
GO

/* ----------------------------------------------------------------------
   Seed ~5,000 customers.

   The "numbers CTE via cross join on sys.all_objects" pattern below is a
   standard T-SQL trick for generating N rows without a loop: sys.all_objects
   is a catalog view that always has several hundred rows in any database,
   so cross-joining it with itself produces far more rows than needed, and
   TOP (n) + ROW_NUMBER() trims it down to exactly n. It's fast because it's
   set-based (no RBAR / row-by-row cursor).
   ---------------------------------------------------------------------- */
;WITH Numbers AS
(
    SELECT TOP (5000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.Customers (Name, Country, SignupDate)
SELECT
    N'Customer ' + CAST(n AS NVARCHAR(10)),
    CASE n % 5 WHEN 0 THEN N'UK' WHEN 1 THEN N'US' WHEN 2 THEN N'DE' WHEN 3 THEN N'VN' ELSE N'AU' END,
    DATEADD(DAY, -(n % 1000), CAST(GETDATE() AS DATE))
FROM Numbers;
GO

/* ----------------------------------------------------------------------
   Seed ~200,000 orders, spread across the 5,000 customers and across the
   last ~2 years, so date-range queries (pagination, LAG/LEAD over time)
   have realistic spread instead of everything landing on one day.
   ---------------------------------------------------------------------- */
;WITH Numbers AS
(
    SELECT TOP (200000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b CROSS JOIN sys.all_objects c
)
INSERT INTO dbo.Orders (CustomerId, OrderDate, Status, TotalAmount)
SELECT
    (n % 5000) + 1,
    DATEADD(MINUTE, -(n % 1051200), SYSDATETIME()),   -- spread over ~2 years
    CASE n % 20                                        -- ~5% Pending, rest mixed
        WHEN 0 THEN 'Pending'
        WHEN 1 THEN 'Cancelled'
        WHEN 2 THEN 'Shipped'
        ELSE 'Delivered'
    END,
    CAST(((n % 490) + 10) AS DECIMAL(10,2))            -- amounts between 10.00 and 499.00
FROM Numbers;
GO

/* ----------------------------------------------------------------------
   Seed ~500,000 order items (roughly 2.5 items per order on average).
   ---------------------------------------------------------------------- */
;WITH Numbers AS
(
    SELECT TOP (500000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b CROSS JOIN sys.all_objects c
)
INSERT INTO dbo.OrderItems (OrderId, ProductName, Quantity, UnitPrice)
SELECT
    (n % 200000) + 1,
    N'Product ' + CAST((n % 300) AS NVARCHAR(10)),
    (n % 5) + 1,
    CAST(((n % 200) + 5) AS DECIMAL(10,2))
FROM Numbers;
GO

-- Refresh statistics so the optimizer's cardinality estimates (used by every
-- later script's execution plan) reflect the actual seeded data rather than
-- stale/default stats from empty tables.
UPDATE STATISTICS dbo.Customers WITH FULLSCAN;
UPDATE STATISTICS dbo.Orders WITH FULLSCAN;
UPDATE STATISTICS dbo.OrderItems WITH FULLSCAN;
GO
