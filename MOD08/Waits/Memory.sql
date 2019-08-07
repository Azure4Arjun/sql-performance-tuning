SELECT cntr_value 'Total Pages'
FROM sys.dm_os_performance_counters 
WHERE object_name LIKE '%Buffer Manager%' 
AND counter_name ='Total Pages';

SELECT cntr_value 'Target Pages'
FROM sys.dm_os_performance_counters 
WHERE object_name LIKE '%Buffer Manager%' 
AND counter_name ='Target Pages';
GO

SELECT cntr_value/60 'Page Life Expectancy min.'
FROM sys.dm_os_performance_counters 
WHERE object_name LIKE '%Buffer Manager%' 
AND counter_name ='Page Life Expectancy';
GO

SELECT CAST
	((SELECT CAST(cntr_value * 100 AS FLOAT) 
	FROM sys.dm_os_performance_counters 
	WHERE counter_name = 'Buffer cache hit ratio') 
	/ 
	(SELECT cntr_value 
	FROM sys.dm_os_performance_counters  
	WHERE counter_name = 'Buffer cache hit ratio base') AS NUMERIC (5, 2));
GO

DBCC MEMORYSTATUS 
GO

SELECT [type], sum(multi_pages_kb) AS mem 
FROM sys.dm_os_memory_clerks 
WHERE multi_pages_kb != 0 
GROUP BY type
ORDER BY sum(multi_pages_kb) DESC;
GO

SELECT TOP 10 [type], SUM(single_pages_kb) as [SPA Mem, Kb]
FROM sys.dm_os_memory_clerks
GROUP BY [type]
ORDER BY sum(single_pages_kb) DESC
GO

--Buffer cache per db
SELECT
  CASE
    WHEN database_id = 32767 THEN 'mssqlsystemresource'
    ELSE DB_NAME(database_id)
  END AS [Database],
  CONVERT(numeric(38,2),(8.0 / 1024) * COUNT(*)) AS [In buffer cache (MB)]
FROM sys.dm_os_buffer_descriptors
GROUP BY database_id
ORDER BY 2 DESC;

-- Cached Plans per type
SELECT 
  objtype, 
  COUNT(*) AS num_of_plans,
  CONVERT(numeric(18,2),SUM(size_in_bytes) / (1024.0 * 1024)) AS megabytes
FROM sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY megabytes DESC;
GO

-- Cached Plans
SELECT TOP(100) [text], cp.size_in_bytes
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(plan_handle) 
WHERE cp.cacheobjtype = N'Compiled Plan' 
AND cp.objtype = N'Adhoc' 
AND cp.usecounts = 1
ORDER BY cp.size_in_bytes DESC;