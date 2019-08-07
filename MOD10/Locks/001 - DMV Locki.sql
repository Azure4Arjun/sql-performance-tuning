SELECT
  d2.session_id,
  program_name,
  login_name,
  command,
  d1.status,
  blocking_session_id,
  wait_type,
  wait_resource,
  d3.text
FROM   sys.dm_exec_requests AS d1 INNER JOIN sys.dm_exec_sessions d2
ON  d1.session_id = d2.session_id CROSS APPLY sys.dm_exec_sql_text(d1.sql_handle) AS d3
WHERE   blocking_session_id > 0


SELECT 
	request_session_id,
	resource_type,
	DB_NAME(resource_database_id) as DatabaseName,
	OBJECT_NAME(resource_associated_entity_id) as TableName,
	request_mode,
	request_type,
	request_status
FROM sys.dm_tran_locks as TL JOIN sys.all_objects as A0 on TL.resource_associated_entity_id = A0.object_id
where request_type = 'LOCK' and request_status = 'GRANT'
and request_mode IN ('X','S') and A0.type = 'U'
and resource_type = 'OBJECT' and TL.resource_database_id = DB_ID();


SELECT  
	TL1.resource_type,
	DB_NAME(TL1.resource_database_id) as DatabaseName,
	CASE TL1.resource_type
		WHEN 'OBJECT' THEN OBJECT_NAME(TL1.resource_associated_entity_id, TL1.resource_database_id)
		WHEN 'DATABASE' THEN 'DATABASE'
	ELSE
		CASE 
			WHEN TL1.resource_database_id = DB_ID() THEN 
				(SELECT OBJECT_NAME(object_id, TL1.resource_database_id) FROM sys.partitions
                                                   WHERE hobt_id = TL1.resource_associated_entity_id)
			ELSE NULL
		END
	END as ObjectName,
	TL1.resource_description,
	TL1.request_session_id,
	TL1.request_mode,
	TL1.request_status
FROM sys.dm_tran_locks as TL1 JOIN sys.dm_tran_locks as TL2 on TL1.resource_associated_entity_id = TL2.resource_associated_entity_id
WHERE TL1.request_status <>TL2.request_status and (TL1.resource_description=TL2.resource_description
OR(TL1.resource_description IS NULL AND TL2.resource_description IS NULL))
order by TL1.resource_database_id, TL1.resource_associated_entity_id, TL1.request_status ASC;

exec sp_lock
