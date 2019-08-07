/*

	Training:	Optimizing and Troubleshooting
	Module:		01 - Internal Structure and Functioning SQL Server
	Verion:		1.0
	Trainer: Lukasz Grala
	Email:	 lukasz@sqlexpert.pl

	Copyright by SQLExpert.pl 

*/
SELECT * FROM sys.dm_exec_connections;
GO
SELECT * FROM sys.dm_os_schedulers;
GO
SELECT * FROM sys.dm_exec_requests;
GO
SELECT * FROM sys.dm_os_workers;
GO
SELECT * FROM sys.dm_os_tasks;
GO
SELECT * FROM sys.dm_os_threads;
GO

SELECT parent_node_id, scheduler_id, cpu_id, is_online, current_tasks_count, 
runnable_tasks_count, current_workers_count, active_workers_count, work_queue_count, pending_disk_io_count, load_factor
FROM sys.dm_os_schedulers;
GO

SELECT  scheduler_id, current_tasks_count, runnable_tasks_count 
FROM  sys.dm_os_schedulers 
WHERE  scheduler_id < 255
GO

SELECT AVG(current_tasks_count) AS [Avg Task Count], 
AVG(runnable_tasks_count) AS [Avg Runnable Task Count]
FROM sys.dm_os_schedulers
WHERE scheduler_id < 255
AND [status] = 'VISIBLE ONLINE';
GO

SELECT is_preemptive, is_fiber,last_wait_type, affinity, state, quantum_used
FROM sys.dm_os_workers;
GO

SELECT session_id, R.status, command, W.state
FROM sys.dm_exec_requests AS R JOIN sys.dm_os_workers AS W
ON R.task_address = W.task_address;
GO

SELECT task_state, context_switches_count, pending_io_byte_count, pending_io_count, 
pending_io_byte_average, scheduler_id, session_id
FROM sys.dm_os_tasks;
GO

SELECT session_id, wait_duration_ms, wait_type, resource_address, resource_description, blocking_session_id, blocking_task_address, blocking_exec_context_id
FROM sys.dm_os_waiting_tasks;
GO

SELECT *
FROM sys.dm_os_wait_stats;
GO

SELECT signal_wait_time_ms=SUM(signal_wait_time_ms),
'%signal waits' = CAST(100.0 * sum(signal_wait_time_ms) / SUM (wait_time_ms) 
AS NUMERIC(20,2)),
resource_wait_time_ms=SUM(wait_time_ms - signal_wait_time_ms),
'%resource waits'= CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) 
/ SUM (wait_time_ms) AS NUMERIC(20,2))
FROM sys.dm_os_wait_stats;
GO


SELECT  
    r.session_id, 
    r.request_id, 
    max(isnull(exec_context_id, 0)) as number_of_workers, 
    r.sql_handle, 
    r.statement_start_offset, 
    r.statement_end_offset, 
    r.plan_handle 
FROM  
    sys.dm_exec_requests r 
    JOIN sys.dm_os_tasks t on r.session_id = t.session_id 
    JOIN sys.dm_exec_sessions s on r.session_id = s.session_id 
WHERE s.is_user_process = 0x1 
GROUP BY  
    r.session_id, r.request_id,  
    r.sql_handle, r.plan_handle,  
    r.statement_start_offset, r.statement_end_offset 
HAVING MAX(ISNULL(exec_context_id, 0)) > 0;
GO