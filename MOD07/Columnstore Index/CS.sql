USE AdventureWorksDW2012;
GO

SELECT * 
FROM sys.sysmessages 
WHERE description LIKE '%columnstore%' 
AND msglangid = 1033;
GO

SELECT * 
FROM sys.indexes
WHERE type_desc = 'NONCLUSTERED COLUMNSTORE';
GO

SELECT c.name, s.*
FROM sys.indexes AS i
INNER JOIN sys.partitions AS p
ON i.object_id = p.object_id 
AND i.index_id = p.index_id
INNER JOIN sys.column_store_segments AS s
ON s.partition_id = p.partition_id
AND s.hobt_id = p.hobt_id
INNER JOIN sys.columns AS c
ON p.object_id = c.object_id
AND s.column_id = c.column_id
WHERE i.name = 'IX_CS_FactInternetSalesBig_AllColumns'
AND c.name = 'OrderDateKey'
ORDER BY s.column_id, s.segment_id, s.min_data_id, s.max_data_id;
GO

SELECT * 
FROM sys.column_store_dictionaries;
GO

SELECT SUM(on_disk_size_MB) AS TotalSizeInMB
FROM
(
  (
    SELECT SUM(css.on_disk_size)/(1024.0*1024.0) on_disk_size_MB
    FROM sys.indexes AS i
    JOIN sys.partitions AS p
    ON i.object_id = p.object_id 
    JOIN sys.column_store_segments AS css
    ON css.hobt_id = p.hobt_id
    WHERE i.object_id = object_id('dbo.FactInternetSalesBig') 
    AND i.type_desc = 'NONCLUSTERED COLUMNSTORE'
  ) 
  UNION ALL
  (
    SELECT SUM(csd.on_disk_size)/(1024.0*1024.0) on_disk_size_MB
    FROM sys.indexes AS i
    JOIN sys.partitions AS p
    ON i.object_id = p.object_id 
    JOIN sys.column_store_dictionaries AS csd
    ON csd.hobt_id = p.hobt_id
    WHERE i.object_id = object_id('dbo.FactInternetSalesBig') 
    AND i.type_desc = 'NONCLUSTERED COLUMNSTORE'
  ) 
) AS SegmentsPlusDictionary;
GO

DBCC IND('AdventureWorksDW2012', 'dbo.FactInternetSalesBig', 7);
GO
DBCC TRACEON(3604);
DBCC PAGE(AdventureWorksDW2012, 1, 1536072, 3);
GO

--==================================
-- Performance - batch vs. row mode
--==================================

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT 
  P.ProductKey, 
  P.EnglishProductName, 
  COUNT(*) AS OrderCount,
  SUM(F.OrderQuantity) AS Quantity
FROM dbo.DimProduct AS P
INNER JOIN dbo.FactInternetSalesBig AS F
ON P.ProductKey = F.ProductKey
GROUP BY P.ProductKey, P.EnglishProductName
ORDER BY COUNT(*) DESC, Quantity DESC
OPTION (MAXDOP 0);

SELECT 
  P.ProductKey, 
  P.EnglishProductName, 
  COUNT(*) AS OrderCount,
  SUM(F.OrderQuantity) AS Quantity
FROM dbo.DimProduct AS P
INNER JOIN dbo.FactInternetSalesBig AS F
ON P.ProductKey = F.ProductKey
GROUP BY P.ProductKey, P.EnglishProductName
ORDER BY COUNT(*) DESC, Quantity DESC
OPTION (MAXDOP 1);

SELECT 
  P.ProductKey, 
  P.EnglishProductName, 
  COUNT(*) AS OrderCount,
  SUM(F.OrderQuantity) AS Quantity
FROM dbo.DimProduct AS P
INNER JOIN dbo.FactInternetSalesBig AS F
ON P.ProductKey = F.ProductKey
GROUP BY P.ProductKey, P.EnglishProductName
ORDER BY COUNT(*) DESC, Quantity DESC
OPTION (MAXDOP 0, IGNORE_NONCLUSTERED_COLUMNSTORE_INDEX);

SELECT 
  P.ProductKey, 
  P.EnglishProductName, 
  COUNT(*) AS OrderCount,
  SUM(F.OrderQuantity) AS Quantity
FROM dbo.DimProduct AS P
INNER JOIN dbo.FactInternetSalesBig AS F
ON P.ProductKey = F.ProductKey
GROUP BY P.ProductKey, P.EnglishProductName
ORDER BY COUNT(*) DESC, Quantity DESC
OPTION (MAXDOP 1, IGNORE_NONCLUSTERED_COLUMNSTORE_INDEX);

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

--==================================
-- Performance - GROUPING SETS
--==================================

-- Batch mode, 0s
SELECT 
  D.CalendarYear,
  D.MonthNumberOfYear,
  P.ProductKey, 
  P.EnglishProductName, 
  COUNT(*) AS OrderCount,
  SUM(F.OrderQuantity) AS Quantity,
  SUM(F.SalesAmount) AS SalesAmount
FROM dbo.DimProduct AS P
INNER JOIN dbo.FactInternetSalesBig AS F
ON P.ProductKey = F.ProductKey
INNER JOIN dbo.DimDate AS D
ON F.OrderDateKey = D.DateKey
GROUP BY GROUPING SETS (
  (P.ProductKey, P.EnglishProductName, D.CalendarYear, D.MonthNumberOfYear), 
  (P.ProductKey, P.EnglishProductName, D.CalendarYear)
)
ORDER BY D.CalendarYear, D.MonthNumberOfYear, P.EnglishProductName;
GO

--====================================
-- Performance - segment elimination
--====================================

SELECT * 
FROM sys.dm_xe_objects 
WHERE name LIKE '%column%store%' 
GO 

IF EXISTS (
  SELECT * 
  FROM sys.dm_xe_sessions
  WHERE name = 'SegmentEliminationSession'
)
  DROP EVENT SESSION SegmentEliminationSession ON SERVER;
GO

-- Sesja XE
CREATE EVENT SESSION SegmentEliminationSession 
ON SERVER 
ADD EVENT sqlserver.column_store_segment_eliminate 
(
  ACTION (
    sqlserver.database_id,
    sqlserver.session_id,
    sqlserver.sql_text,
    sqlserver.plan_handle
  )
) 
ADD TARGET package0.asynchronous_file_target 
(
  SET FILENAME = 'C:\Temp\SegmentEliminationSession.xel', 
  METADATAFILE = 'C:\Temp\SegmentEliminationSession.xem'
);
GO

ALTER EVENT SESSION SegmentEliminationSession 
ON SERVER STATE = START; 
GO 

SELECT 
  D.CalendarYear,
  D.MonthNumberOfYear,
  CONVERT(char(4), D.CalendarYear) + '-' +
  RIGHT('00' + CONVERT(varchar(2), D.MonthNumberOfYear), 2) AS Month,
  SUM(F.SalesAmount)/1000000 AS SalesAmount,
  T.SalesAmountTarget/1000000. AS SalesAmountTarget
FROM dbo.DimProduct AS P
INNER JOIN dbo.FactInternetSalesBig AS F
ON P.ProductKey = F.ProductKey
INNER JOIN dbo.DimDate AS D
ON F.OrderDateKey = D.DateKey
INNER JOIN dbo.DimTargets AS T
ON D.CalendarYear = T.CalendarYear 
AND D.MonthNumberOfYear = T.MonthNumberOfYear
WHERE D.CalendarYear = 2007
GROUP BY 
  D.CalendarYear, D.MonthNumberOfYear, T.SalesAmountTarget
ORDER BY D.CalendarYear, D.MonthNumberOfYear;
GO

SELECT * 
FROM sys.fn_xe_file_target_read_file(
  'C:\sql\*.xel', 'C:\sql\SegmentEliminationSession.xem', NULL, NULL
) AS Q;
GO

DBCC TRACEON (3604, -1);
DBCC TRACEON (646, -1);
DBCC TRACEON (3605, -1);
GO

GO
---- PERFORMANCE
SELECT 
  D.CalendarYear,
  D.MonthNumberOfYear,
  P.ProductKey, 
  P.EnglishProductName, 
  COUNT(*) AS OrderCount,
  SUM(F.OrderQuantity) AS Quantity,
  SUM(F.SalesAmount) AS SalesAmount
FROM dbo.DimProduct AS P
LEFT JOIN dbo.FactInternetSalesBig AS F
ON P.ProductKey = F.ProductKey
LEFT JOIN dbo.DimDate AS D
ON F.OrderDateKey = D.DateKey
GROUP BY P.ProductKey, P.EnglishProductName, D.CalendarYear, D.MonthNumberOfYear
ORDER BY D.CalendarYear, D.MonthNumberOfYear, P.EnglishProductName;
GO


WITH CTE AS (
  SELECT 
    D.CalendarYear,
    D.MonthNumberOfYear,
    P.ProductKey, 
    P.EnglishProductName, 
    COUNT(*) AS OrderCount,
    SUM(F.OrderQuantity) AS Quantity,
    SUM(F.SalesAmount) AS SalesAmount
  FROM dbo.DimProduct AS P
  INNER JOIN dbo.FactInternetSalesBig AS F
  ON P.ProductKey = F.ProductKey
  INNER JOIN dbo.DimDate AS D
  ON F.OrderDateKey = D.DateKey
  GROUP BY P.ProductKey, P.EnglishProductName, D.CalendarYear, D.MonthNumberOfYear
)
SELECT
  C.CalendarYear,
  C.MonthNumberOfYear,
  P1.ProductKey, 
  P1.EnglishProductName, 
  ISNULL(C.OrderCount, 0) AS OrderCount,
  ISNULL(C.Quantity, 0) AS Quantity,
  ISNULL(C.SalesAmount, 0) AS SalesAmount
FROM dbo.DimProduct AS P1
LEFT JOIN CTE AS C
ON P1.ProductKey = C.ProductKey
ORDER BY C.CalendarYear, C.MonthNumberOfYear, P1.EnglishProductName;
GO

-- NEXT
SELECT 
  P.ProductKey, 
  P.EnglishProductName, 
  COUNT(*) AS OrderCount,
  SUM(F.OrderQuantity) AS Quantity
FROM dbo.DimProduct AS P
LEFT JOIN dbo.FactInternetSalesBig AS F
ON P.ProductKey = F.ProductKey
GROUP BY P.ProductKey, P.EnglishProductName
ORDER BY COUNT(*) DESC, Quantity DESC;
GO

-- UNION ALL
SELECT 
  D.CalendarYear,
  D.MonthNumberOfYear,
  P.ProductKey, 
  P.EnglishProductName, 
  COUNT(*) AS OrderCount,
  SUM(F.OrderQuantity) AS Quantity,
  SUM(F.SalesAmount) AS SalesAmount
FROM (
  SELECT *
  FROM dbo.FactInternetSalesBig
  UNION ALL
  SELECT *
  FROM dbo.FactInternetSalesActuals
) AS F
INNER JOIN dbo.DimProduct AS P
ON P.ProductKey = F.ProductKey
INNER JOIN dbo.DimDate AS D
ON F.OrderDateKey = D.DateKey
GROUP BY 
  P.ProductKey, P.EnglishProductName, 
  D.CalendarYear, D.MonthNumberOfYear
ORDER BY D.CalendarYear, D.MonthNumberOfYear, P.EnglishProductName;
GO

WITH CTE AS (
  SELECT
    D.CalendarYear,
    D.MonthNumberOfYear,
    P.ProductKey, 
    P.EnglishProductName, 
    COUNT(*) AS OrderCount,
    SUM(F.OrderQuantity) AS Quantity,
    SUM(F.SalesAmount) AS SalesAmount
  FROM dbo.FactInternetSalesBig AS F
  INNER JOIN dbo.DimProduct AS P
  ON P.ProductKey = F.ProductKey
  INNER JOIN dbo.DimDate AS D
  ON F.OrderDateKey = D.DateKey
  GROUP BY 
    P.ProductKey, P.EnglishProductName, 
    D.CalendarYear, D.MonthNumberOfYear 
), CTE1 AS (
    SELECT
    D.CalendarYear,
    D.MonthNumberOfYear,
    P.ProductKey, 
    P.EnglishProductName, 
    COUNT(*) AS OrderCount,
    SUM(F.OrderQuantity) AS Quantity,
    SUM(F.SalesAmount) AS SalesAmount
  FROM dbo.FactInternetSalesActuals AS F
  INNER JOIN dbo.DimProduct AS P
  ON P.ProductKey = F.ProductKey
  INNER JOIN dbo.DimDate AS D
  ON F.OrderDateKey = D.DateKey
  GROUP BY 
    P.ProductKey, P.EnglishProductName, 
    D.CalendarYear, D.MonthNumberOfYear 
), CTE2 AS (
  SELECT *
  FROM CTE
  UNION ALL
  SELECT *
  FROM CTE1
)
SELECT 
  CalendarYear,
  MonthNumberOfYear,
  ProductKey, 
  EnglishProductName, 
  SUM(OrderCount) AS OrderCount,
  SUM(Quantity) AS Quantity,
  SUM(SalesAmount) AS SalesAmount
FROM CTE2
GROUP BY 
  ProductKey, EnglishProductName, 
  CalendarYear, MonthNumberOfYear
ORDER BY CalendarYear, MonthNumberOfYear, EnglishProductName;
GO

--
SELECT 
  D.CalendarYear,
  D.MonthNumberOfYear,
  COUNT(*) AS OrderCount,
  SUM(F.OrderQuantity) AS Quantity,
  SUM(F.SalesAmount) AS SalesAmount
FROM (
  SELECT *
  FROM dbo.FactInternetSalesBig
  UNION ALL
  SELECT *
  FROM dbo.FactInternetSalesActuals
) AS F
INNER JOIN dbo.DimDate AS D
ON F.OrderDateKey = D.DateKey
GROUP BY D.CalendarYear, D.MonthNumberOfYear
ORDER BY D.CalendarYear, D.MonthNumberOfYear;
GO
