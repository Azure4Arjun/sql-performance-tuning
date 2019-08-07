--Part 1
USE AdventureWorks2008R2;
GO
 
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name ='usp_Orders')
	 DROP PROCEDURE usp_Orders
GO

CREATE PROCEDURE [dbo].[usp_Orders]
(@CustID INT)
AS
SELECT h.[SalesOrderID], COUNT(h.[SalesOrderID]), SUM([TotalDue])
FROM Sales.SalesOrderHeader h JOIN Sales.SalesOrderDetail d
ON h.SalesOrderID = d.SalesOrderId
WHERE h.[CustomerID] = @CustID
GROUP BY h.[SalesOrderID];
GO

EXEC sp_configure 'show advanced options',1
RECONFIGURE
EXEC sp_configure 'optimize for ad hoc workloads', 0
EXEC sp_configure 'xp_cmdshell',1
RECONFIGURE
GO
 
SET STATISTICS TIME ON
GO
 
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS 
GO

xp_cmdshell 'C:\SQL\ExecSP.exe'
GO

SELECT SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
 ((CASE qs.statement_end_offset
	WHEN -1 THEN DATALENGTH(qt.TEXT)
	ELSE qs.statement_end_offset
	END - qs.statement_start_offset)/2)+1) AS [Statement],
 qs.execution_count,
 qs.max_worker_time,
 qs.max_elapsed_time,
 qs.max_logical_reads,
 qp.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE qt.text LIKE '%Sales.SalesOrderHeader%'
AND qt.text NOT LIKE '%dm_exec_sql_text%'
ORDER BY execution_count DESC;
GO

DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS 
GO
 
xp_cmdshell 'C:\SQL\ExecAdHoc.exe'
GO

SELECT SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
 ((CASE qs.statement_end_offset
	WHEN -1 THEN DATALENGTH(qt.TEXT)
	ELSE qs.statement_end_offset
	END - qs.statement_start_offset)/2)+1) AS [Statement],
 qs.execution_count,
 qs.max_worker_time,
 qs.max_elapsed_time,
 qs.max_logical_reads,
 qp.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE qt.text LIKE '%Sales.SalesOrderHeader%'
AND qt.text NOT LIKE '%dm_exec_sql_text%'
ORDER BY execution_count DESC;
GO

SELECT cp.usecounts, cp.size_in_bytes, objtype, qt.text, qp.query_plan
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS qt
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp
WHERE qt.text LIKE '%Sales.SalesOrderHeader%'
AND qt.text NOT like '%dm_exec_sql_text%';
GO

SELECT objtype AS [CacheType],
	COUNT_BIG(*) AS [Total Plans],
	SUM(CAST(size_in_bytes AS decimal(18,2)))/1024/1024 AS [Total MBs],
    AVG(usecounts) AS [Avg Use Count]
FROM sys.dm_exec_cached_plans 
CROSS APPLY sys.dm_exec_sql_text(plan_handle) as qt
WHERE qt.text LIKE '%Sales.SalesOrderHeader%'
AND qt.text NOT LIKE '%dm_exec_sql_text%'
GROUP BY objtype;
GO

--Part 2

DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS 
GO
 
xp_cmdshell 'c:\sql\ExecPrepared.exe'
GO

SELECT objtype AS [CacheType],
	COUNT_BIG(*) AS [Total Plans],
	SUM(CAST(size_in_bytes AS decimal(18,2)))/1024/1024 AS [Total MBs],
    AVG(usecounts) AS [Avg Use Count]
FROM sys.dm_exec_cached_plans 
CROSS APPLY sys.dm_exec_sql_text(plan_handle) as qt
WHERE qt.text LIKE '%Sales.SalesOrderHeader%'
AND qt.text NOT LIKE '%dm_exec_sql_text%'
GROUP BY objtype;
GO

EXEC sp_configure 'optimize for ad hoc workloads', 1
RECONFIGURE
GO

DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
 
xp_cmdshell 'c:\sql\ExecAdHoc.exe'
GO

SELECT cp.usecounts, cp.size_in_bytes, objtype, qt.text, qp.query_plan
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS qt
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp
WHERE qt.text LIKE '%Sales.SalesOrderHeader%'
AND qt.text NOT like '%dm_exec_sql_text%';
GO

SELECT objtype AS [CacheType],
	COUNT_BIG(*) AS [Total Plans],
	SUM(CAST(size_in_bytes AS decimal(18,2)))/1024/1024 AS [Total MBs],
    AVG(usecounts) AS [Avg Use Count]
FROM sys.dm_exec_cached_plans 
CROSS APPLY sys.dm_exec_sql_text(plan_handle) as qt
WHERE qt.text LIKE '%Sales.SalesOrderHeader%'
AND qt.text NOT LIKE '%dm_exec_sql_text%'
GROUP BY objtype;
GO

ALTER DATABASE [AdventureWorks2008R2] 
SET PARAMETERIZATION FORCED 
WITH NO_WAIT;
GO

DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
 
xp_cmdshell 'c:\sql\ExecAdHoc.exe'
GO


--Clean up
ALTER DATABASE [AdventureWorks2008R2] 
SET PARAMETERIZATION SIMPLE 
WITH NO_WAIT
GO
 
EXEC sp_configure 'xp_cmdshell',0
EXEC sp_configure 'optimize for ad hoc workloads', 0
EXEC sp_configure 'show advanced options',0
RECONFIGURE
GO
SET STATISTICS TIME OFF