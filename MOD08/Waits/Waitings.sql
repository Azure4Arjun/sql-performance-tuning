SELECT session_id, R.status, command, W.state
FROM sys.dm_exec_requests AS R JOIN sys.dm_os_workers AS W
ON R.task_address = W.task_address;
GO

SELECT session_id, wait_duration_ms, wait_type, resource_address, resource_description, 
	blocking_session_id, blocking_task_address, blocking_exec_context_id
FROM sys.dm_os_waiting_tasks;
GO


WITH Waits AS
(SELECT wait_type, wait_time_ms / 1000. AS wait_time_s, 
100. * wait_time_ms / SUM(wait_time_ms) OVER() AS pct, 
ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS rn
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE'
,'SLEEP_SYSTEMTASK','SQLTRACE_BUFFER_FLUSH','WAITFOR', 'LOGMGR_QUEUE','CHECKPOINT_QUEUE'
,'REQUEST_FOR_DEADLOCK_SEARCH','XE_TIMER_EVENT','BROKER_TO_FLUSH','BROKER_TASK_STOP',
'CLR_MANUAL_EVENT','CLR_AUTO_EVENT','DISPATCHER_QUEUE_SEMAPHORE',
'FT_IFTS_SCHEDULER_IDLE_WAIT','XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN')
AND wait_type NOT LIKE '%SLEEP%' AND wait_type NOT LIKE 'PREEMPTIVE%')
SELECT
 W1.wait_type, 
 CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s,
 CAST(W1.pct AS DECIMAL(12, 2)) AS pct,
 CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct
FROM Waits AS W1
 JOIN Waits AS W2
 ON W2.rn <= W1.rn
GROUP BY W1.rn, W1.wait_type, W1.wait_time_s, W1.pct
HAVING W1.rn <11 
ORDER BY W1.rn;
GO

WITH [Latches] AS
     (SELECT
         [latch_class],
         [wait_time_ms] / 1000.0 AS [WaitS],
         [waiting_requests_count] AS [WaitCount],
         100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
         ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
     FROM sys.dm_os_latch_stats
     WHERE [latch_class] NOT IN (
         N'BUFFER')
     AND [wait_time_ms] > 0
     )
 SELECT
     [W1].[latch_class] AS [LatchClass], 
    CAST ([W1].[WaitS] AS DECIMAL(14, 2)) AS [Wait_S],
     [W1].[WaitCount] AS [WaitCount],
     CAST ([W1].[Percentage] AS DECIMAL(14, 2)) AS [Percentage],
     CAST (([W1].[WaitS] / [W1].[WaitCount]) AS DECIMAL (14, 4)) AS [AvgWait_S]
 FROM [Latches] AS [W1]
 INNER JOIN [Latches] AS [W2]
     ON [W2].[RowNum] <= [W1].[RowNum]
 WHERE [W1].[WaitCount] > 0
 GROUP BY [W1].[RowNum], [W1].[latch_class], [W1].[WaitS], [W1].[WaitCount], [W1].[Percentage]
 --HAVING SUM ([W2].[Percentage]) - [W1].[Percentage] <95; -- percentage threshold
 GO 