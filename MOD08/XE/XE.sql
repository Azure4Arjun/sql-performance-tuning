-- First, what events are there that I can use?
SELECT * 
FROM sys.dm_xe_objects 
WHERE [object_type] = 'event'
ORDER BY [name];
GO

-- We're going to user sql_statement_completed. What are the columns?
SELECT [object_name], name,column_type,column_value
FROM sys.dm_xe_object_columns
WHERE [object_name] IN( 'sql_statement_completed', 'lock_acquired');
GO

-- What database and resource governor actions are there?
SELECT * 
FROM sys.dm_xe_objects 
WHERE [object_type] = 'action'
ORDER BY [name];
GO

-- What targets are there?
SELECT * 
FROM sys.dm_xe_objects 
WHERE [object_type] = 'target'
ORDER BY [name];
GO

-- Let's use the ring buffer. What can I customize about it?
SELECT name, description, column_value
FROM sys.dm_xe_object_columns
WHERE [object_name] = 'ring_buffer'
GO

SELECT * FROM sys.dm_xe_object_columns
WHERE [object_name] = '
asynchronous_bucketizer'

-- Drop the session if it exists. 
IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name = 'MonitorCPU')
    DROP EVENT SESSION MonitorCPU ON SERVER
GO

-- Create the event session
CREATE EVENT SESSION LocksAcquired ON SERVER
ADD EVENT sqlserver.lock_acquired
	(WHERE sqlserver.database_id = 20)
ADD TARGET package0.asynchronous_bucketizer 
	(SET filtering_event_name='sqlserver.lock_acquired'
	,source_type=0
	,source='mode');
GO

ALTER EVENT SESSION LocksAcquired ON SERVER 
STATE=START;
GO

SELECT map_value as blockType, Nr 
FROM
	(
	SELECT C.value(' (./value)[1] ', 'int') as [id_blokady]
	,C.value('@count', 'int') as Nr
	FROM (
	SELECT CAST(xest.target_data AS XML).query('//Slot') LockData
	FROM sys.dm_xe_session_targets xest
		JOIN sys.dm_xe_sessions xes 
			ON xes.address = xest.event_session_address
		JOIN sys.server_event_sessions ses 
ON xes.name = ses.name 
	WHERE xes.name = 'LocksAcquired') AS Locks
	CROSS APPLY LockData.nodes('/Slot') AS T(C)) AS LockedObjects 
INNER JOIN sys.dm_xe_map_values AS M
	ON LockedObjects.[id_blokady] = M.map_key
WHERE M.name='lock_mode'
ORDER by Nr DESC;
GO

ALTER EVENT SESSION LocksAcquired ON SERVER 
STATE=STOP;
GO

CREATE EVENT SESSION MonitorIO ON SERVER
ADD EVENT sqlserver.sql_statement_completed
	(ACTION
		(sqlserver.database_id)
    )
ADD TARGET package0.ring_buffer
WITH (max_dispatch_latency = 1 seconds);
GO

-- Start the session
ALTER EVENT SESSION MonitorIO ON SERVER
STATE = START;
GO

-- Go back and run the two sets of RunQueriesWithWait

-- Look at some of the output
SELECT CAST(xest.target_data AS XML) StatementData
	FROM sys.dm_xe_session_targets xest
JOIN sys.dm_xe_sessions xes ON xes.address = xest.event_session_address
WHERE xest.target_name = 'ring_buffer'
AND xes.name = 'MonitorIO';
GO

-- Now do some processing on it
-- Select some of the output
SELECT
	Data2.Results.value ('(data/.)[2]', 'int') AS ObjectID,
	Data2.Results.value ('(data/.)[6]', 'bigint') AS Reads,
	Data2.Results.value ('(data/.)[7]', 'bigint') AS Writes,
	Data2.Results.value ('(action/.)[1]', 'int') AS DatabaseID
FROM
(SELECT CAST(xest.target_data AS XML) StatementData
FROM sys.dm_xe_session_targets xest
JOIN sys.dm_xe_sessions xes ON xes.address = xest.event_session_address
WHERE xest.target_name = 'ring_buffer' AND xes.name = 'MonitorIO') Statements
CROSS APPLY StatementData.nodes ('//RingBufferTarget/event') AS Data2 (Results);
GO

-- Select the IO sums by resource pool using a derived table
SELECT DB_NAME(DT.DatabaseID) as DB, 
SUM (DT.Reads) as TotalReads, 
SUM (DT.Writes) AS TotalWrites
FROM
(SELECT 
	Data2.Results.value ('(data/.)[6]', 'bigint') AS Reads,
	Data2.Results.value ('(data/.)[7]', 'bigint') AS Writes,
	Data2.Results.value ('(action/.)[1]', 'int') AS DatabaseID
FROM
(SELECT CAST(xest.target_data AS XML) StatementData
FROM sys.dm_xe_session_targets xest
JOIN sys.dm_xe_sessions xes 
ON xes.address = xest.event_session_address
WHERE xest.target_name = 'ring_buffer' 
AND xes.name = 'MonitorIO') Statements
CROSS APPLY StatementData.nodes ('//RingBufferTarget/event') AS Data2 (Results)) AS DT
GROUP BY DT.DatabaseID;
GO

ALTER EVENT SESSION MonitorCPU ON SERVER
STATE = STOP;
GO
