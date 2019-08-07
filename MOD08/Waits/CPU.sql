SELECT scheduler_id,current_tasks_count, runnable_tasks_count
FROM sys.dm_os_schedulers
WHERE scheduler_id < 255;
GO

SELECT scheduler_id, session_id, status, command 
FROM sys.dm_exec_requests
WHERE status = 'runnable'
AND session_id > 50
ORDER BY scheduler_id;
GO

SELECT signal_wait_time_ms = 
	sum(signal_wait_time_ms),
	'%signal waits' = cast(100.0 * sum(signal_wait_time_ms) / 
	sum (wait_time_ms) as numeric(20,2)),
	resource_wait_time_ms = 
	sum(wait_time_ms - signal_wait_time_ms),
	'%resource waits' = 
	cast(100.0 * sum(wait_time_ms - signal_wait_time_ms) / 
	sum (wait_time_ms) as numeric(20,2))
FROM sys.dm_os_wait_stats;
GO

SELECT * 
FROM sys.dm_exec_query_optimizer_info;
GO

SELECT * 
FROM sys.dm_exec_query_optimizer_info
WHERE counter in 
('optimizations','elapsed time','trivial plan','tables','insert stmt','update stmt','delete stmt');
GO

SELECT cntr_value 'SQL Compilations/sec'
FROM sys.dm_os_performance_counters 
WHERE object_name LIKE '%SQL Statistics%' 
AND counter_name ='SQL Compilations/sec';

SELECT cntr_value 'SQL Re-Compilations/sec'
FROM sys.dm_os_performance_counters 
WHERE object_name LIKE '%SQL Statistics%' 
AND counter_name ='SQL Re-Compilations/sec';
GO

SELECT ISNULL(value,0.0) AS ElapsedTimePerOptimization
FROM sys.dm_exec_query_optimizer_info 
WHERE counter = 'elapsed time';
GO

SELECT * FROM sys.dm_exec_cursors(NULL)
WHERE fetch_buffer_size = 1 -- TSQL cursor
AND properties LIKE 'API%'	-- API cursor 
GO

--Retrieve Statements with the Lowest Plan Re-Use Counts
SELECT TOP 50
        qs.sql_handle
		,qs.plan_handle
		,cp.cacheobjtype
		,cp.usecounts
		,cp.size_in_bytes  
		,qs.statement_start_offset
		,qs.statement_end_offset
		,qt.dbid
		,qt.objectid
		,qt.text
		,SUBSTRING(qt.text,qs.statement_start_offset/2, 
			(CASE WHEN qs.statement_end_offset = -1 
				THEN len(convert(nvarchar(max), qt.text)) * 2 
				ELSE qs.statement_end_offset end -qs.statement_start_offset)/2) 
		AS statement
FROM sys.dm_exec_query_stats qs
cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
inner join sys.dm_exec_cached_plans AS cp on qs.plan_handle=cp.plan_handle
WHERE cp.plan_handle=qs.plan_handle
--and qt.dbid = db_id()
ORDER BY [dbid],[Usecounts] ASC;
GO

--Retrieve Statements with the Highest AVG CPU cost
SELECT TOP 50
        SUBSTRING(qt.text,qs.statement_start_offset/2, 
			(case when qs.statement_end_offset = -1 
			then len(convert(nvarchar(max), qt.text)) * 2 
			else qs.statement_end_offset end -qs.statement_start_offset)/2) 
		AS query_text,
		(qs.total_worker_time/qs.execution_count)/1000. AS [AvgCPUTime]
		,Execution_count 
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
ORDER BY [AvgCPUTime] DESC;
GO

--Retrieve Statements with the Highest CPU cost

SELECT highest_cpu_queries.total_worker_time /1000. AS highest_cpu_queries, q.[text]
FROM (SELECT TOP 50 qs.plan_handle, qs.total_worker_time
	FROM sys.dm_exec_query_stats qs
	ORDER BY qs.total_worker_time desc) as highest_cpu_queries
CROSS APPLY sys.dm_exec_sql_text(plan_handle) as q
ORDER BY highest_cpu_queries.total_worker_time DESC;
GO