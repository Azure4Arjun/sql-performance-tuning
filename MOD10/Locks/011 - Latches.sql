SELECT * FROM sys.dm_os_wait_stats
WHERE wait_type like '%latch%'
GO
SELECT * FROM sys.dm_os_latch_stats;
GO

--- Analyzing Current Wait Buffer Latches
SELECT wt.session_id, wt.wait_type
, er.last_wait_type AS last_wait_type
, wt.wait_duration_ms
, wt.blocking_session_id, wt.blocking_exec_context_id, resource_description
FROM sys.dm_os_waiting_tasks wt
JOIN sys.dm_exec_sessions es ON wt.session_id = es.session_id
JOIN sys.dm_exec_requests er ON wt.session_id = er.session_id
WHERE es.is_user_process = 1
AND wt.wait_type <> 'SLEEP_TASK'
ORDER BY wt.wait_duration_ms desc;
GO

select * from sys.dm_os_latch_stats where latch_class <> 'BUFFER' order by wait_time_ms desc
GO

