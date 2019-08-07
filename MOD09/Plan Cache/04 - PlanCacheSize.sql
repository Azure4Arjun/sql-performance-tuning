-- Examining Size of Plan Cache

-- There are many caches besides plan cache
SELECT * 
FROM sys.dm_os_memory_cache_counters;

-- There are four types of plan cache stores
SELECT *
FROM sys.dm_os_memory_cache_hash_tables 
WHERE type IN ('CACHESTORE_OBJCP', 'CACHESTORE_SQLCP', 
                   'CACHESTORE_PHDR', 'CACHESTORE_XPROC');

-- Only SQL Cache Store and Object Plan Store hold compiled queries
-- This query shows the space used by these two cache stores 
SELECT (SUM(pages_in_use_kb ) * 8  / (1024.0 * 1024.0)) as plan_cache_in_GB,type
FROM sys.dm_os_memory_cache_counters 
WHERE type = 'CACHESTORE_SQLCP' or type = 'CACHESTORE_OBJCP'
GROUP BY type;


SELECT type, count(*) total_entries
FROM sys.dm_os_memory_cache_entries
WHERE type IN ('CACHESTORE_SQLCP', 'CACHESTORE_OBJCP')
GROUP BY type;
GO

--count of the number of compiled plans use:
SELECT COUNT(*)
FROM sys.dm_Exec_Cached_plans 
WHERE cacheobjtype = 'Compiled Plan';


SELECT st.text, cp.cacheobjtype, cp.objtype, cp.refcounts, cp.usecounts, cp.size_in_bytes, cp.bucketid, cp.plan_handle
FROM sys.dm_exec_cached_plans cp 
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st 
WHERE cp.cacheobjtype = 'Compiled Plan' AND (cp.objtype = 'Prepared' or cp.objtype = 'Adhoc' )
ORDER BY cp.usecounts DESC;

--estimate the amount of plan cache memory that is being reused use:
SELECT SUM(size_in_bytes)/1000 AS total_size_in_KB, 
	COUNT(size_in_bytes) as number_of_plans, 
	((SUM(size_in_bytes)/1000) / (COUNT(size_in_bytes))) AS avg_size_in_KB,
	cacheobjtype, usecounts 
FROM sys.dm_exec_cached_plans 
GROUP BY  usecounts, cacheobjtype
ORDER BY usecounts ASC;


-- First, verify the state of your cache... is it filled with "USE Count 1" plans?
SELECT objtype AS [Cache Store Type], COUNT_BIG(*) AS [Total Num Of Plans],  SUM(CAST(size_in_bytes as decimal(14,2))) / 1048576 AS [Total Size In MB],
AVG(usecounts) AS [All Plans - Ave Use Count], SUM(CAST((CASE WHEN usecounts = 1 THEN size_in_bytes ELSE 0 END) AS DECIMAL(14,2)))/ 1048576 AS [Size in MB of plans with a Use count = 1],
SUM(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) AS [Number of of plans with a Use count = 1]
FROM sys.dm_exec_cached_plans        
GROUP BY objtype        
ORDER BY [Size in MB of plans with a Use count = 1] DESC
GO

-- current and original cost of any cache entry, as well as 
-- the components that make up that cost.

SELECT text, objtype, refcounts, usecounts, size_in_bytes,
       disk_ios_count, context_switches_count,
       original_cost, current_cost
FROM sys.dm_exec_cached_plans p
	CROSS APPLY sys.dm_exec_sql_text(plan_handle)
	JOIN sys.dm_os_memory_cache_entries e
        ON p.memory_object_address = e.memory_object_address
WHERE cacheobjtype = 'Compiled Plan'
  AND type in ('CACHESTORE_SQLCP', 'CACHESTORE_OBJCP')
ORDER BY objtype desc, usecounts DESC;

-- Here's your top 100
SELECT TOP(100) [text], cp.size_in_bytes
FROM sys.dm_Exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(plan_handle) 
WHERE cacheobjtype = 'Compiled Plan' 
AND cp.objtype = 'Adhoc' 
AND cp.usecounts = 1
ORDER BY cp.size_in_bytes DESC;
GO


