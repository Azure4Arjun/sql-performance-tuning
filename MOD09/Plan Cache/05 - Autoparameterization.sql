USE pubs;
GO

-- Auto parameterized and cached...
SELECT * 
FROM titles 
WHERE price = $19.99

-- So, will subsequent executions use it?
SELECT * 
FROM titles 
WHERE price = $19.99

-- But what if there's a different value?
SELECT * 
FROM titles 
WHERE price = $7.99 -- money

SELECT * 
FROM titles 
WHERE price = 7.99 -- still money?

SELECT * 
FROM titles 
WHERE price = 19.99 -- still the same?
GO

DBCC FREEPROCCACHE 
GO
USE [AdventureWorks]
GO

DECLARE @SalesOrderID VARCHAR(20) 
DECLARE @SQL NVARCHAR(MAX)  
DECLARE @TableVar TABLE (SalesOrderID INT)   

DECLARE CursorExample CURSOR FOR 
SELECT SalesOrderID 
FROM Sales.SalesOrderHeader  

OPEN CursorExample 
FETCH NEXT FROM CursorExample INTO @SalesOrderID  

WHILE @@FETCH_STATUS = 0 
BEGIN  

	SET @SQL = 'SELECT SalesOrderID 
	FROM Sales.SalesOrderHeader h 
	JOIN Sales.SalesPerson p on p.[SalesPersonID] = h.SalesPersonID 
	WHERE SalesOrderID = ' + @SalesOrderID  

	INSERT INTO @TableVar(SalesOrderID) 
	EXECUTE (@SQL)  

	FETCH NEXT FROM CursorExample INTO @SalesOrderID 
END  

CLOSE CursorExample 
DEALLOCATE CursorExample 
GO

SELECT PlanSizeInMB = SUM(size_in_bytes)/1024.0/1024.0 
FROM sys.dm_exec_cached_plans 
CROSS APPLY sys.dm_exec_sql_text(plan_handle) 
WHERE text LIKE '%SalesOrderHeader%' AND 
text NOT LIKE '%dm_exec_cached_plans%' 
GO

EXEC SP_CONFIGURE 'show advanced options',1
RECONFIGURE
GO
EXEC SP_CONFIGURE 'optimize for ad hoc workloads',1
RECONFIGURE
GO

--And finally forced autoparamatrization
EXEC SP_CONFIGURE 'optimize for ad hoc workloads',0
RECONFIGURE
GO

ALTER DATABASE [AdventureWorks]
SET PARAMETERIZATION FORCED

--Sum it up
SELECT objtype AS [Cache Store Type],
        COUNT_BIG(*) AS [Total Num Of Plans],
        SUM(CAST(size_in_bytes as decimal(14,2))) / 1048576 AS [Total Size In MB],
        AVG(usecounts) AS [All Plans - Ave Use Count],
        SUM(CAST((CASE WHEN usecounts = 1 THEN size_in_bytes ELSE 0 END) as decimal(14,2)))/ 1048576 AS [Size in MB of plans with a Use count = 1],
        SUM(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) AS [Number of of plans with a Use count = 1]
        FROM sys.dm_exec_cached_plans
        GROUP BY objtype
        ORDER BY [Size in MB of plans with a Use count = 1] DESC
DECLARE @AdHocSizeInMB decimal (14,2), @TotalSizeInMB decimal (14,2)
SELECT @AdHocSizeInMB = SUM(CAST((CASE WHEN usecounts = 1 AND LOWER(objtype) = 'adhoc' THEN size_in_bytes ELSE 0 END) as decimal(14,2))) / 1048576,
        @TotalSizeInMB = SUM (CAST (size_in_bytes as decimal (14,2))) / 1048576
        FROM sys.dm_exec_cached_plans 
SELECT @AdHocSizeInMB as [Current memory occupied by adhoc plans only used once (MB)],
         @TotalSizeInMB as [Total cache plan size (MB)],
         CAST((@AdHocSizeInMB / @TotalSizeInMB) * 100 as decimal(14,2)) as [% of total cache plan occupied by adhoc plans only used once]
IF  @AdHocSizeInMB > 200 or ((@AdHocSizeInMB / @TotalSizeInMB) * 100) > 25  -- 200MB or > 25%
        SELECT 'Switch on Optimize for ad hoc workloads as it will make a significant difference' as [Recommendation]
ELSE
        SELECT 'Setting Optimize for ad hoc workloads will make little difference' as [Recommendation]
GO