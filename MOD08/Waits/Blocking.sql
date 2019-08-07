SELECT cntr_value 'Processes blocked'
FROM sys.dm_os_performance_counters
WHERE object_name LIKE '%General Statistics%'
AND counter_name ='Processes blocked';
GO

SELECT cntr_value 'Number of Deadlocks/sec'
FROM sys.dm_os_performance_counters
WHERE object_name LIKE '%Locks%'
AND counter_name ='Number of Deadlocks/sec'
AND instance_name = '_Total';
GO

DECLARE @dbid int = db_id()
SELECT dbid = database_id, objectname = object_name(s.object_id),
indexname = i.name, i.index_id, -- partition_number, row_lock_count, row_lock_wait_count,
[block %] = cast (100.0 * row_lock_wait_count / (1 + row_lock_count) as numeric(15,2)),
row_lock_wait_in_ms,
[avg row lock waits in ms] = cast (1.0 * row_lock_wait_in_ms /
(1 + row_lock_wait_count) as numeric(15,2))
FROM sys.dm_db_index_operational_stats (@dbid, NULL, NULL, NULL) s
JOIN sys.indexes i 
ON i.object_id = s.object_id and i.index_id = s.index_id
WHERE objectproperty(s.object_id, 'IsUserTable') = 1
ORDER BY row_lock_wait_count DESC;
GO

SELECT t1.resource_type
	,db_name(resource_database_id) as [database]
	,t1.resource_associated_entity_id as [blk object]
	,t1.request_mode
	,t1.request_session_id   -- spid of waiter
	,(SELECT text FROM sys.dm_exec_requests as r  --- get sql for waiter
		CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) 
		where r.session_id = t1.request_session_id) as waiter_text
	,t2.blocking_session_id  -- spid of blocker
     ,(SELECT TEXT FROM sys.sysprocesses as p		--- get sql for blocker
		CROSS APPLY sys.dm_exec_sql_text(p.sql_handle) WHERE p.spid = t2.blocking_session_id) as blocker_text
	FROM 
	sys.dm_tran_locks AS t1, 
	sys.dm_os_waiting_tasks AS t2
WHERE 
	t1.lock_owner_address = t2.resource_address;
GO

