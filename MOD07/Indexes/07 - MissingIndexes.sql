USE AdventureWorks
GO
SELECT OrderQty
FROM Sales.SalesOrderDetail
WHERE OrderQty >30
ORDER BY OrderQty
GO

SELECT *
FROM Sales.SalesOrderHeader
WHERE DueDate ='2004-08-12 00:00:00.000'

SELECT g.*
FROM sys.dm_db_missing_index_groups AS g
go

SELECT s.*
FROM sys.dm_db_missing_index_group_stats AS s
go

SELECT d.*
FROM sys.dm_db_missing_index_details AS d
go

SELECT d.*
		, s.avg_total_user_cost
		, s.avg_user_impact
		, s.last_user_seek
		, s.unique_compiles
		, s.*
FROM sys.dm_db_missing_index_group_stats AS s
	JOIN sys.dm_db_missing_index_groups AS g
		ON s.group_handle = g.index_group_handle 
	JOIN sys.dm_db_missing_index_details AS d
		ON d.index_handle = g.index_handle
ORDER BY s.avg_user_impact DESC
go

/* ------------------------------------------------------------------
-- Title:	FindMissingIndexes
-- Author:	Brent Ozar
-- Date:	2009-04-01 
-- Modified By: Clayton Kramer <ckramer.kramer gmail.com="" @="">
-- Description: This query returns indexes that SQL Server 2005 
-- (and higher) thinks are missing since the last restart. The 
-- "Impact" column is relative to the time of last restart and how 
-- bad SQL Server needs the index. 10 million+ is high.
-- Changes: Updated to expose full table name. This makes it easier
-- to identify which database needs an index. Modified the 
-- CreateIndexStatement to use the full table path and include the
-- equality/inequality columns for easier identifcation.
------------------------------------------------------------------ */

SELECT  
	[Impact] = (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans),  
	[Table] = [statement],
	[CreateIndexStatement] = 'CREATE NONCLUSTERED INDEX ix_' 
		+ sys.objects.name COLLATE DATABASE_DEFAULT 
		+ '_' 
		+ REPLACE(REPLACE(REPLACE(ISNULL(mid.equality_columns,'')+ISNULL(mid.inequality_columns,''), '[', ''), ']',''), ', ','_')
		+ ' ON ' 
		+ [statement] 
		+ ' ( ' + IsNull(mid.equality_columns, '') 
		+ CASE WHEN mid.inequality_columns IS NULL THEN '' ELSE 
			CASE WHEN mid.equality_columns IS NULL THEN '' ELSE ',' END 
		+ mid.inequality_columns END + ' ) ' 
		+ CASE WHEN mid.included_columns IS NULL THEN '' ELSE 'INCLUDE (' + mid.included_columns + ')' END 
		+ ';', 
	mid.equality_columns,
	mid.inequality_columns,
	mid.included_columns
FROM sys.dm_db_missing_index_group_stats AS migs 
	INNER JOIN sys.dm_db_missing_index_groups AS mig ON migs.group_handle = mig.index_group_handle 
	INNER JOIN sys.dm_db_missing_index_details AS mid ON mig.index_handle = mid.index_handle 
	INNER JOIN sys.objects WITH (nolock) ON mid.OBJECT_ID = sys.objects.OBJECT_ID 
WHERE (migs.group_handle IN 
		(SELECT TOP (500) group_handle 
		FROM sys.dm_db_missing_index_group_stats WITH (nolock) 
		ORDER BY (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) DESC))  
	AND OBJECTPROPERTY(sys.objects.OBJECT_ID, 'isusertable') = 1 
ORDER BY [Impact] DESC , [CreateIndexStatement] DESC
