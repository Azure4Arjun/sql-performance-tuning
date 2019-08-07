SELECT * FROM sys.dm_tran_locks;

SELECt * FROM sys.dm_exec_requests;

SELECT * FROM sys.dm_os_waiting_tasks;
GO

IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID('[dbo].[[Blocks]'))
DROP VIEW [dbo].[Blocks]
GO

CREATE VIEW [Blocks]
AS
SELECT 
	request_session_id as [SPID],
	DB_NAME(resource_database_id) as [DB],
	CASE
		WHEN resource_type = 'OBJECT' THEN OBJECT_NAME(resource_associated_entity_id)
		WHEN resource_associated_entity_id = 0 THEN 'brak'
		ELSE OBJECT_NAME(p.object_id)
	END as [Object],
	index_id as [IndexID],
	resource_type as [Resource],
	resource_description as [Description],
	request_mode as [Mode],
	request_status as [Status]
FROM sys.dm_tran_locks t LEFT JOIN sys.partitions p ON p.hobt_id = t.resource_associated_entity_id
WHERE resource_database_id = DB_ID();
GO

select * from [Blocks]